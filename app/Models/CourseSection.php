<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CourseSection extends Model
{
    use HasFactory;

    protected $fillable = ['course_id', 'title', 'description', 'order_position'];

    protected $casts = ['order_position' => 'integer'];

    public function course() { return $this->belongsTo(Course::class); }
    public function lessons() { return $this->hasMany(CourseLesson::class)->orderBy('order_position', 'asc'); }
    public function publishedLessons() { return $this->lessons()->where('is_published', true); }
}
