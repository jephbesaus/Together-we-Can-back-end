<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Follow extends Model
{
    use HasFactory;

    protected $fillable = ['follower_id', 'following_id'];

    protected $appends = ['time_ago'];

    public function follower() { return $this->belongsTo(User::class, 'follower_id'); }
    public function following() { return $this->belongsTo(User::class, 'following_id'); }

    public function getTimeAgoAttribute() { return $this->created_at->diffForHumans(); }

    public static function isFollowing($followerId, $followingId)
    {
        return self::where('follower_id', $followerId)->where('following_id', $followingId)->exists();
    }

    public static function toggle($followerId, $followingId)
    {
        $existing = self::where('follower_id', $followerId)->where('following_id', $followingId)->first();

        if ($existing) {
            $existing->delete();
            User::where('id', $followerId)->decrement('following_count');
            User::where('id', $followingId)->decrement('followers_count');
            return false;
        }

        self::create(['follower_id' => $followerId, 'following_id' => $followingId]);
        User::where('id', $followerId)->increment('following_count');
        User::where('id', $followingId)->increment('followers_count');
        return true;
    }
}
