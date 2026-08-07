<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Referral extends Model
{
    use HasFactory;

    protected $fillable = ['referrer_id', 'referred_id', 'status', 'reward_amount', 'rewarded_at'];

    protected $casts = [
        'reward_amount' => 'decimal:2',
        'rewarded_at' => 'datetime',
    ];

    public function referrer() { return $this->belongsTo(User::class, 'referrer_id'); }
    public function referred() { return $this->belongsTo(User::class, 'referred_id'); }

    public function complete()
    {
        $this->update(['status' => 'completed', 'rewarded_at' => now()]);
        $rewardAmount = config('referrals.reward_amount', 500);
        $this->referrer->increment('boost_balance', $rewardAmount);
        $this->referrer->increment('referral_earnings', $rewardAmount);
    }
}
