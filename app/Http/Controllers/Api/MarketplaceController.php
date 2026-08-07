<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Order;
use App\Models\Review;
use App\Models\Favorite;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class MarketplaceController extends Controller
{
    use \App\Traits\ApiResponseTrait;

    public function index(Request $request)
    {
        $query = Product::approved()->active();

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('q')) {
            $query->search($request->q);
        }

        if ($request->filled('min_price') && $request->filled('max_price')) {
            $query->priceRange($request->min_price, $request->max_price);
        }

        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $total = (clone $query)->count();
        $products = $query->with('seller')
            ->orderBy('created_at', 'desc')
            ->skip($offset)
            ->take($limit)
            ->get();

        return $this->successResponse([
            'products' => $products,
            'has_more' => ($offset + $products->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function categories()
    {
        $categories = Product::approved()->active()
            ->whereNotNull('category')
            ->distinct()
            ->pluck('category');

        return $this->successResponse(['categories' => $categories]);
    }

    public function show($id)
    {
        $product = Product::with(['seller', 'reviews.user'])->find($id);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $product->incrementViews();

        $isFavorited = Favorite::isFavorited(auth()->id(), $id);

        return $this->successResponse([
            'product' => $product,
            'is_favorited' => $isFavorited,
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:5000',
            'price' => 'required|numeric|min:0',
            'category' => 'nullable|string|max:100',
            'images' => 'nullable|array',
            'images.*' => 'file|mimes:jpeg,png,gif|max:5120',
            'location' => 'nullable|string|max:255',
            'contact_info' => 'nullable|string|max:255',
            'stock_quantity' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $imageUrls = [];
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $path = $image->store('products/' . date('Y/m/d'), 'public');
                $imageUrls[] = Storage::url($path);
            }
        }

        $product = Product::create([
            'seller_id' => auth()->id(),
            'name' => $request->name,
            'description' => $request->description,
            'price' => $request->price,
            'category' => $request->category,
            'images' => $imageUrls,
            'location' => $request->location,
            'contact_info' => $request->contact_info,
            'stock_quantity' => $request->stock_quantity,
            'is_active' => true,
            'is_approved' => false,
        ]);

        return $this->successResponse([
            'message' => 'Product submitted for approval.',
            'product' => $product,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $product = Product::where('seller_id', auth()->id())->find($id);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:5000',
            'price' => 'sometimes|numeric|min:0',
            'category' => 'nullable|string|max:100',
            'stock_quantity' => 'nullable|integer|min:0',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $product->update($request->only(['name', 'description', 'price', 'category', 'stock_quantity', 'is_active']));

        return $this->successResponse([
            'message' => 'Product updated successfully.',
            'product' => $product->fresh(),
        ]);
    }

    public function destroy($id)
    {
        $product = Product::where('seller_id', auth()->id())->find($id);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $product->delete();

        return $this->successResponse(['message' => 'Product deleted successfully.']);
    }

    public function placeOrder(Request $request, $productId)
    {
        $product = Product::find($productId);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'quantity' => 'required|integer|min:1',
            'shipping_address' => 'nullable|string|max:255',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        if ($product->is_out_of_stock) {
            return $this->errorResponse('Product is out of stock.', 400);
        }

        $order = Order::create([
            'product_id' => $productId,
            'buyer_id' => auth()->id(),
            'seller_id' => $product->seller_id,
            'quantity' => $request->quantity,
            'total_price' => $product->price * $request->quantity,
            'status' => 'pending',
            'shipping_address' => $request->shipping_address,
            'notes' => $request->notes,
        ]);

        if ($product->stock_quantity !== null) {
            $product->decrement('stock_quantity', $request->quantity);
        }

        Notification::create([
            'user_id' => $product->seller_id,
            'type' => 'marketplace',
            'message' => 'Nouvelle commande pour ' . $product->name,
            'data' => json_encode(['order_id' => $order->id, 'product_id' => $product->id]),
            'has_sound' => true,
        ]);

        return $this->successResponse([
            'message' => 'Order placed successfully.',
            'order' => $order->load('product'),
        ], 201);
    }

    public function orders(Request $request)
    {
        $userId = auth()->id();
        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        $baseQuery = Order::forUser($userId);
        $total = (clone $baseQuery)->count();

        $orders = $baseQuery
            ->with(['product', 'buyer', 'seller'])
            ->orderBy('created_at', 'desc')
            ->skip($offset)
            ->take($limit)
            ->get();

        return $this->successResponse([
            'orders' => $orders,
            'has_more' => ($offset + $orders->count()) < $total,
            'total' => $total,
            'page' => $page,
        ]);
    }

    public function orderDetails($id)
    {
        $userId = auth()->id();

        $order = Order::forUser($userId)->with(['product', 'buyer', 'seller'])->find($id);

        if (!$order) {
            return $this->errorResponse('Order not found.', 404);
        }

        return $this->successResponse(['order' => $order]);
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $order = Order::where('seller_id', auth()->id())->find($id);

        if (!$order) {
            return $this->errorResponse('Order not found.', 404);
        }

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,confirmed,processing,shipped,delivered,completed,cancelled,refunded',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $order->update(['status' => $request->status]);

        Notification::create([
            'user_id' => $order->buyer_id,
            'type' => 'marketplace',
            'message' => 'Votre commande est maintenant : ' . Order::STATUS_LABELS[$request->status],
            'data' => json_encode(['order_id' => $order->id]),
            'has_sound' => true,
        ]);

        return $this->successResponse([
            'message' => 'Order status updated.',
            'order' => $order->fresh(),
        ]);
    }

    public function addReview(Request $request, $productId)
    {
        $validator = Validator::make($request->all(), [
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
            'order_id' => 'nullable|integer|exists:orders,id',
        ]);

        if ($validator->fails()) {
            return $this->errorResponse($validator->errors(), 422);
        }

        $product = Product::find($productId);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $review = Review::create([
            'product_id' => $productId,
            'user_id' => auth()->id(),
            'order_id' => $request->order_id,
            'rating' => $request->rating,
            'comment' => $request->comment,
        ]);

        return $this->successResponse([
            'message' => 'Review added successfully.',
            'review' => $review->load('user'),
        ], 201);
    }

    public function toggleFavorite($productId)
    {
        $product = Product::find($productId);

        if (!$product) {
            return $this->errorResponse('Product not found.', 404);
        }

        $isFavorited = Favorite::toggle(auth()->id(), $productId);

        return $this->successResponse(['favorited' => $isFavorited]);
    }

    public function favorites()
    {
        $favorites = Favorite::where('user_id', auth()->id())
            ->with('product.seller')
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->successResponse(['favorites' => $favorites]);
    }
}
