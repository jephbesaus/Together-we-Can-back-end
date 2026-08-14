<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Post extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id', 'content', 'media_type', 'media_url', 'thumbnail_url',
        'is_announcement', 'is_story', 'story_expires_at', 'likes_count',
        'comments_count', 'shares_count', 'views_count', 'is_published', 'is_reported'
    ];

    protected $casts = [
        'is_announcement' => 'boolean',
        'is_story' => 'boolean',
        'is_published' => 'boolean',
        'is_reported' => 'boolean',
        'story_expires_at' => 'datetime',
        'media_url' => 'array',
    ];

    protected $appends = ['is_liked_by_user', 'media_urls', 'time_ago', 'is_story_active'];

    public function user() { return $this->belongsTo(User::class); }
    public function comments() { return $this->hasMany(Comment::class); }
    public function likes() { return $this->hasMany(Like::class); }
    public function reports() { return $this->hasMany(Report::class); }

    public function getIsLikedByUserAttribute()
    {
        if (!auth()->check()) return false;
        return $this->likes()->where('user_id', auth()->id())->exists();
    }

    public function getMediaUrlsAttribute()
    {
        if (empty($this->media_url)) return [];
        $urls = $this->isJson($this->media_url) ? json_decode($this->media_url, true) : [$this->media_url];
        return array_values(array_map(
            fn ($url) => \App\Support\MediaHelper::absoluteUrl($url),
            $urls
        ));
    }

    public function getThumbnailUrlAttribute(?string $value)
    {
        return $value ? \App\Support\MediaHelper::absoluteUrl($value) : null;
    }

    public function getTimeAgoAttribute() { return $this->created_at->diffForHumans(); }

    public function getIsStoryActiveAttribute()
    {
        if (!$this->is_story) return false;
        if (!$this->story_expires_at) return true;
        return now()->lessThan($this->story_expires_at);
    }

    private function isJson($string) { if (!is_string($string)) return false; json_decode($string); return json_last_error() === JSON_ERROR_NONE; }

    public function scopePublished($query) { return $query->where('is_published', true); }
    public function scopeStories($query) { return $query->where('is_story', true)->where(function($q) { $q->whereNull('story_expires_at')->orWhere('story_expires_at', '>', now()); }); }
    public function scopeNotStories($query) { return $query->where('is_story', false); }

    public function incrementLikes() { $this->increment('likes_count'); }
    public function decrementLikes() { $this->decrement('likes_count'); }
    public function incrementComments() { $this->increment('comments_count'); }
    public function incrementShares() { $this->increment('shares_count'); }
    public function incrementViews() { $this->increment('views_count'); }
}
