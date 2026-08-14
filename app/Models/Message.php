<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Message extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'sender_id', 'receiver_id', 'conversation_id', 'content', 'media_url',
        'media_type', 'is_read', 'read_at', 'is_deleted_by_sender',
        'is_deleted_by_receiver', 'reply_to_id', 'seen_at', 'delivered_at'
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'is_deleted_by_sender' => 'boolean',
        'is_deleted_by_receiver' => 'boolean',
        'read_at' => 'datetime',
        'seen_at' => 'datetime',
        'delivered_at' => 'datetime',
    ];

    protected $appends = ['time_ago', 'is_sent_by_user'];

    public function sender() { return $this->belongsTo(User::class, 'sender_id'); }
    public function receiver() { return $this->belongsTo(User::class, 'receiver_id'); }
    public function conversation() { return $this->belongsTo(Conversation::class); }
    public function replyTo() { return $this->belongsTo(Message::class, 'reply_to_id'); }

    public function getTimeAgoAttribute() { return $this->created_at->diffForHumans(); }

    public function getMediaUrlAttribute(?string $value)
    {
        return $value ? \App\Support\MediaHelper::absoluteUrl($value) : null;
    }

    public function getIsSentByUserAttribute()
    {
        if (!auth()->check()) return false;
        return $this->sender_id === auth()->id();
    }

    public function scopeUnread($query) { return $query->where('is_read', false); }
    public function scopeForUser($query, $userId) { return $query->where(function ($q) use ($userId) { $q->where('sender_id', $userId)->orWhere('receiver_id', $userId); }); }
}
