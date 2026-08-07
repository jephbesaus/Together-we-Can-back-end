<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Conversation extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user1_id', 'user2_id', 'last_message_id', 'last_message_at',
        'is_archived_for_user1', 'is_archived_for_user2',
        'blocked_by_user1', 'blocked_by_user2'
    ];

    protected $casts = [
        'is_archived_for_user1' => 'boolean',
        'is_archived_for_user2' => 'boolean',
        'blocked_by_user1' => 'boolean',
        'blocked_by_user2' => 'boolean',
        'last_message_at' => 'datetime',
    ];

    public function user1() { return $this->belongsTo(User::class, 'user1_id'); }
    public function user2() { return $this->belongsTo(User::class, 'user2_id'); }
    public function lastMessage() { return $this->belongsTo(Message::class, 'last_message_id'); }
    public function messages() { return $this->hasMany(Message::class)->orderBy('created_at', 'asc'); }

    public function getOtherUser($userId)
    {
        if ($this->user1_id === $userId) return $this->user2;
        return $this->user1;
    }

    public function getUnreadCount($userId)
    {
        return $this->messages()->where('receiver_id', $userId)->where('is_read', false)->count();
    }

    public function isBlockedFor($userId)
    {
        if ($this->user1_id === $userId) return $this->blocked_by_user1;
        if ($this->user2_id === $userId) return $this->blocked_by_user2;
        return false;
    }

    public function scopeForUser($query, $userId) { return $query->where('user1_id', $userId)->orWhere('user2_id', $userId); }
}
