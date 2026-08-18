<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'name', 'email', 'phone', 'password', 'profile_photo', 'cover_photo',
        'bio', 'role', 'is_premium', 'premium_requested', 'is_verified',
        'is_blocked', 'followers_count', 'following_count', 'boost_balance',
        'savings_balance', 'referral_code', 'referred_by', 'referral_count',
        'referral_earnings', 'referral_expires_at', 'device_token',
        'device_platform', 'device_id', 'otp', 'otp_expires_at', 'last_active'
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'is_premium' => 'boolean',
        'is_verified' => 'boolean',
        'is_blocked' => 'boolean',
        'boost_balance' => 'decimal:2',
        'savings_balance' => 'decimal:2',
        'otp_expires_at' => 'datetime',
        'last_active' => 'datetime',
    ];

    protected $appends = ['profile_photo_url'];

    public function posts() { return $this->hasMany(Post::class); }
    public function comments() { return $this->hasMany(Comment::class); }
    public function likes() { return $this->hasMany(Like::class); }
    public function messagesSent() { return $this->hasMany(Message::class, 'sender_id'); }
    public function messagesReceived() { return $this->hasMany(Message::class, 'receiver_id'); }
    public function followers() { return $this->belongsToMany(User::class, 'follows', 'following_id', 'follower_id'); }
    public function following() { return $this->belongsToMany(User::class, 'follows', 'follower_id', 'following_id'); }
    public function products() { return $this->hasMany(Product::class, 'seller_id'); }
    public function orders() { return $this->hasMany(Order::class, 'buyer_id'); }
    public function boostOrders() { return $this->hasMany(BoostOrder::class); }
    public function transactions() { return $this->hasMany(Transaction::class); }
    public function savings() { return $this->hasOne(Savings::class); }
    public function notifications() { return $this->hasMany(Notification::class); }
    public function courseEnrollments() { return $this->hasMany(CourseEnrollment::class); }
    public function referredBy() { return $this->belongsTo(User::class, 'referred_by'); }
    public function referrals() { return $this->hasMany(Referral::class, 'referrer_id'); }
    public function referredUsers() { return $this->hasMany(User::class, 'referred_by'); }

    public function getProfilePhotoUrlAttribute()
    {
        return $this->profile_photo ? asset('storage/' . $this->profile_photo) : 'https://ui-avatars.com/api/?name=' . urlencode($this->name) . '&color=FFFFFF&background=00A86B';
    }

    public function isAdmin() { return $this->role === 'admin'; }
    public function isPremium() { return $this->is_premium; }
    public function isBlocked() { return $this->is_blocked; }

    public static function generateReferralCode()
    {
        do {
            $code = strtoupper(Str::random(8));
        } while (User::where('referral_code', $code)->exists());
        return $code;
    }

    public function getReferralLinkAttribute()
    {
        return 'twc://register?ref=' . $this->referral_code;
    }

    protected static function boot()
    {
        parent::boot();

        static::retrieved(function ($model) {
            if (is_null($model->getAttributes()['boost_balance'] ?? null)) {
                $model->boost_balance = 0;
                $model->saveQuietly();
            }
        });
    }
}
