<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'seller_id', 'name', 'description', 'price', 'category', 'images',
        'video_url', 'location', 'contact_info', 'stock_quantity', 'is_active',
        'is_approved', 'views_count', 'featured', 'expires_at'
    ];

    protected $casts = [
        'images' => 'array',
        'price' => 'decimal:2',
        'is_active' => 'boolean',
        'is_approved' => 'boolean',
        'featured' => 'boolean',
        'stock_quantity' => 'integer',
        'expires_at' => 'datetime',
    ];

    protected $appends = ['main_image', 'formatted_price', 'is_out_of_stock', 'average_rating', 'reviews_count', 'favorites_count'];

    public function seller() { return $this->belongsTo(User::class, 'seller_id'); }
    public function orders() { return $this->hasMany(Order::class); }
    public function favorites() { return $this->hasMany(Favorite::class); }
    public function reviews() { return $this->hasMany(Review::class); }

    public function getImagesAttribute($value)
    {
        $images = is_array($value) ? $value : (json_decode($value ?? '[]', true) ?? []);
        return array_values(array_map(
            fn ($url) => \App\Support\MediaHelper::absoluteUrl($url),
            $images
        ));
    }

    public function getMainImageAttribute() { if ($this->images && is_array($this->images) && count($this->images) > 0) return $this->images[0]; return null; }
    public function getFormattedPriceAttribute() { return number_format($this->price, 0, ',', ' ') . ' CDF'; }
    public function getIsOutOfStockAttribute() { return $this->stock_quantity !== null && $this->stock_quantity <= 0; }
    public function getAverageRatingAttribute() { return $this->reviews()->avg('rating') ?? 0; }
    public function getReviewsCountAttribute() { return $this->reviews()->count(); }
    public function getFavoritesCountAttribute() { return $this->favorites()->count(); }

    public function scopeApproved($query) { return $query->where('is_approved', true); }
    public function scopeActive($query) { return $query->where('is_active', true); }
    public function scopeFeatured($query) { return $query->where('featured', true); }
    public function scopeSearch($query, $term) { return $query->where(function ($q) use ($term) { $q->where('name', 'LIKE', "%{$term}%")->orWhere('description', 'LIKE', "%{$term}%")->orWhere('category', 'LIKE', "%{$term}%"); }); }
    public function scopePriceRange($query, $min, $max) { return $query->whereBetween('price', [$min, $max]); }

    public function incrementViews() { $this->increment('views_count'); }
    public function isOwner($userId) { return $this->seller_id === $userId; }
}
