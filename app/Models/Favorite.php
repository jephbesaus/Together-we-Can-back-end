<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Favorite extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'product_id'];

    public function user() { return $this->belongsTo(User::class); }
    public function product() { return $this->belongsTo(Product::class); }

    public static function isFavorited($userId, $productId)
    {
        return self::where('user_id', $userId)->where('product_id', $productId)->exists();
    }

    public static function toggle($userId, $productId)
    {
        $existing = self::where('user_id', $userId)->where('product_id', $productId)->first();
        if ($existing) { $existing->delete(); return false; }
        self::create(['user_id' => $userId, 'product_id' => $productId]);
        return true;
    }
}
