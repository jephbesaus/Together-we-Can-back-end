<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Comment extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['post_id', 'user_id', 'parent_id', 'content', 'likes_count', 'is_reported'];

    protected $casts = ['is_reported' => 'boolean', 'likes_count' => 'integer'];

    protected $appends = ['is_liked_by_user', 'time_ago'];

    public function user() { return $this->belongsTo(User::class); }
    public function post() { return $this->belongsTo(Post::class); }
    public function parent() { return $this->belongsTo(Comment::class, 'parent_id'); }
    public function replies() { return $this->hasMany(Comment::class, 'parent_id')->orderBy('created_at', 'asc'); }
    public function likes() { return $this->hasMany(Like::class, 'comment_id'); }

    public function getIsLikedByUserAttribute()
    {
        if (!auth()->check()) return false;
        return $this->likes()->where('user_id', auth()->id())->exists();
    }

    public function getTimeAgoAttribute() { return $this->created_at->diffForHumans(); }
}
