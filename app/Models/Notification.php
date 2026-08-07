<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'type', 'title', 'message', 'data',
        'is_read', 'has_sound', 'image_url', 'action_url'
    ];

    protected $casts = ['is_read' => 'boolean', 'has_sound' => 'boolean', 'data' => 'array'];

    protected $appends = ['time_ago', 'type_icon', 'type_color'];

    public function user() { return $this->belongsTo(User::class); }

    public function getTimeAgoAttribute() { return $this->created_at->diffForHumans(); }

    public function getTypeIconAttribute()
    {
        $icons = [
            'message' => 'chat', 'like' => 'favorite', 'comment' => 'comment',
            'share' => 'share', 'follow' => 'person_add', 'premium' => 'verified',
            'premium_approved' => 'verified', 'premium_rejected' => 'cancel',
            'marketplace' => 'shopping_bag', 'boost' => 'trending_up',
            'boost_completed' => 'check_circle', 'announcement' => 'campaign',
            'payment' => 'payment', 'course_enrollment' => 'school',
            'account_blocked' => 'block', 'account_unblocked' => 'check',
            'product_approved' => 'check_circle', 'product_rejected' => 'cancel',
            'transfer_sent' => 'send', 'transfer_received' => 'download'
        ];
        return $icons[$this->type] ?? 'notifications';
    }

    public function getTypeColorAttribute()
    {
        $colors = [
            'message' => '#2196F3', 'like' => '#F44336', 'comment' => '#FF9800',
            'share' => '#4CAF50', 'follow' => '#00BCD4', 'premium' => '#9C27B0',
            'premium_approved' => '#4CAF50', 'premium_rejected' => '#F44336',
            'marketplace' => '#FF5722', 'boost' => '#E91E63',
            'boost_completed' => '#4CAF50', 'announcement' => '#FF5722',
            'payment' => '#4CAF50', 'course_enrollment' => '#3F51B5',
            'account_blocked' => '#F44336', 'account_unblocked' => '#4CAF50',
            'product_approved' => '#4CAF50', 'product_rejected' => '#F44336',
            'transfer_sent' => '#F44336', 'transfer_received' => '#4CAF50'
        ];
        return $colors[$this->type] ?? '#9E9E9E';
    }

    public function scopeUnread($query) { return $query->where('is_read', false); }
    public function scopeImportant($query) { return $query->whereIn('type', ['premium', 'premium_approved', 'premium_rejected', 'marketplace', 'boost', 'boost_completed', 'announcement', 'payment', 'account_blocked', 'account_unblocked']); }
}
