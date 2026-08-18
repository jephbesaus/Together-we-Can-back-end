<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class News extends Model {
    use HasFactory;
    protected $fillable = ['admin_id', 'title', 'content', 'image', 'is_published'];
    protected $casts = ['is_published' => 'boolean'];
    public function admin() { return $this->belongsTo(User::class, 'admin_id'); }
    public function scopePublished($query) { return $query->where('is_published', true); }
}
