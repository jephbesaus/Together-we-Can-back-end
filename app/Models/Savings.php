<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Savings extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'balance', 'total_saved', 'total_withdrawn'];

    protected $casts = [
        'balance' => 'decimal:2',
        'total_saved' => 'decimal:2',
        'total_withdrawn' => 'decimal:2',
    ];

    public function user() { return $this->belongsTo(User::class); }
}
