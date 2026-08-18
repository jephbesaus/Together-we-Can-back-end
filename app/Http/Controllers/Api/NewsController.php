<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\News;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class NewsController extends Controller {
    use \App\Traits\ApiResponseTrait;

    public function index(Request $request) {
        $limit = $request->input('limit', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;
        $query = News::published()->with('admin:id,name');
        $total = (clone $query)->count();
        $items = $query->orderByDesc('created_at')->skip($offset)->take($limit)->get();
        return $this->successResponse(['news' => $items, 'has_more' => ($offset + $items->count()) < $total, 'total' => $total, 'page' => $page]);
    }

    public function store(Request $request) {
        $v = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'content' => 'required|string|max:10000',
            'image' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
            'is_published' => 'boolean',
        ]);
        if ($v->fails()) return $this->errorResponse($v->errors(), 422);
        $imagePath = $request->hasFile('image') ? $request->file('image')->store('news', 'public') : null;
        $news = News::create([
            'admin_id' => auth()->id(),
            'title' => $request->title,
            'content' => $request->content,
            'image' => $imagePath,
            'is_published' => $request->boolean('is_published', false),
        ]);
        return $this->successResponse(['message' => 'Actualité créée.', 'news' => $news], 201);
    }

    public function update(Request $request, $id) {
        $news = News::find($id);
        if (!$news) return $this->errorResponse('Actualité non trouvée.', 404);
        $v = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string|max:10000',
            'image' => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
            'is_published' => 'boolean',
        ]);
        if ($v->fails()) return $this->errorResponse($v->errors(), 422);
        $data = $request->only(['title', 'content', 'is_published']);
        if ($request->hasFile('image')) {
            if ($news->image) Storage::disk('public')->delete($news->image);
            $data['image'] = $request->file('image')->store('news', 'public');
        }
        $news->update($data);
        return $this->successResponse(['message' => 'Actualité mise à jour.', 'news' => $news->fresh()]);
    }

    public function destroy($id) {
        $news = News::find($id);
        if (!$news) return $this->errorResponse('Actualité non trouvée.', 404);
        if ($news->image) Storage::disk('public')->delete($news->image);
        $news->delete();
        return $this->successResponse(['message' => 'Actualité supprimée.']);
    }
}
