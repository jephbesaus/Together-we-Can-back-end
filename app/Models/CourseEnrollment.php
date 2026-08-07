<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CourseEnrollment extends Model
{
    use HasFactory;

    protected $fillable = [
        'course_id', 'user_id', 'progress', 'is_completed', 'completed_at',
        'last_lesson_id', 'last_accessed_at', 'certificate_url', 'expires_at'
    ];

    protected $casts = [
        'progress' => 'integer',
        'is_completed' => 'boolean',
        'completed_at' => 'datetime',
        'last_accessed_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    protected $appends = ['is_active'];

    public function course() { return $this->belongsTo(Course::class); }
    public function user() { return $this->belongsTo(User::class); }
    public function lastLesson() { return $this->belongsTo(CourseLesson::class, 'last_lesson_id'); }

    public function getIsActiveAttribute() { if (!$this->expires_at) return true; return now()->lessThan($this->expires_at); }

    public function updateProgress()
    {
        $totalLessons = $this->course->lessons()->published()->count();
        if ($totalLessons === 0) { $this->progress = 0; return; }
        $completedLessons = LessonProgress::where('user_id', $this->user_id)->whereIn('lesson_id', $this->course->lessons()->pluck('id'))->where('is_completed', true)->count();
        $progress = round(($completedLessons / $totalLessons) * 100);
        $this->update(['progress' => min(100, $progress), 'is_completed' => $progress >= 100, 'completed_at' => $progress >= 100 ? now() : null]);
    }
}
