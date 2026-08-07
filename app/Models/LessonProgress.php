<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LessonProgress extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'lesson_id', 'progress', 'last_position', 'is_completed', 'completed_at', 'watched_duration'];

    protected $casts = [
        'progress' => 'integer',
        'last_position' => 'integer',
        'is_completed' => 'boolean',
        'watched_duration' => 'integer',
        'completed_at' => 'datetime',
    ];

    public function user() { return $this->belongsTo(User::class); }
    public function lesson() { return $this->belongsTo(CourseLesson::class); }

    public static function updateProgress($userId, $lessonId, $position, $duration)
    {
        $progress = self::where('user_id', $userId)->where('lesson_id', $lessonId)->first();
        if (!$progress) { $progress = self::create(['user_id' => $userId, 'lesson_id' => $lessonId, 'progress' => 0, 'last_position' => 0, 'is_completed' => false, 'watched_duration' => 0]); }
        $lesson = CourseLesson::find($lessonId); if (!$lesson || !$lesson->video_duration) return $progress;
        $newProgress = min(100, round(($duration / $lesson->video_duration) * 100));
        $progress->update(['progress' => $newProgress, 'last_position' => $position, 'watched_duration' => $duration, 'is_completed' => $newProgress >= 90, 'completed_at' => $newProgress >= 90 ? now() : null]);
        $enrollment = CourseEnrollment::where('user_id', $userId)->where('course_id', $lesson->course_id)->first();
        if ($enrollment) $enrollment->updateProgress();
        return $progress;
    }
}
