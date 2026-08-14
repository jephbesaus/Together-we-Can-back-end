<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = ['title', 'content', 'image_url', 'is_active', 'is_pinned', 'created_by'];

    protected $casts = ['is_active' => 'boolean', 'is_pinned' => 'boolean'];

    protected $appends = ['time_ago'];

    public function creator() { return $this->belongsTo(User::class, 'created_by'); }
    public function getTimeAgoAttribute() { return $this->created_at->diffForHumans(); }

    public function getImageUrlAttribute(?string $value)
    {
        return $value ? \App\Support\MediaHelper::absoluteUrl($value) : null;
    }

    public function scopeActive($query) { return $query->where('is_active', true); }
}
