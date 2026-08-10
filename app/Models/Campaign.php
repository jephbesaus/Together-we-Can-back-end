<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Campaign extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'title', 'description', 'image_url', 'link',
        'budget', 'start_date', 'end_date', 'status',
        'views_count', 'clicks_count',
    ];

    protected $casts = [
        'budget' => 'decimal:2',
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    protected $appends = ['is_active_now'];

    public function user() { return $this->belongsTo(User::class); }

    public function getIsActiveNowAttribute()
    {
        if ($this->status !== 'active') return false;
        if ($this->end_date && now()->greaterThan($this->end_date)) return false;
        return true;
    }

    public function scopeForUser($query, $userId) { return $query->where('user_id', $userId); }

    public function incrementViews() { $this->increment('views_count'); }
    public function incrementClicks() { $this->increment('clicks_count'); }
}
