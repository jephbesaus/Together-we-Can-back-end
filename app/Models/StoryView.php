<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StoryView extends Model
{
    use HasFactory;

    protected $fillable = ['story_id', 'user_id', 'viewed_at'];

    protected $casts = [
        'viewed_at' => 'datetime',
    ];

    public function story()
    {
        return $this->belongsTo(Post::class, 'story_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
