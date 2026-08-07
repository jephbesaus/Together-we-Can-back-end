<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class CourseLesson extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'course_id', 'section_id', 'title', 'description', 'content',
        'video_url', 'video_duration', 'documents', 'order_position',
        'is_free_preview', 'is_published', 'type'
    ];

    protected $casts = [
        'documents' => 'array',
        'is_free_preview' => 'boolean',
        'is_published' => 'boolean',
        'video_duration' => 'integer',
    ];

    protected $appends = ['video_progress', 'is_completed', 'formatted_duration'];

    public function course() { return $this->belongsTo(Course::class); }
    public function section() { return $this->belongsTo(CourseSection::class); }
    public function progress() { return $this->hasOne(LessonProgress::class); }

    public function getVideoProgressAttribute() { if (!auth()->check()) return 0; $progress = $this->progress()->where('user_id', auth()->id())->first(); return $progress ? $progress->progress : 0; }
    public function getIsCompletedAttribute() { if (!auth()->check()) return false; $progress = $this->progress()->where('user_id', auth()->id())->first(); return $progress ? $progress->is_completed : false; }
    public function getFormattedDurationAttribute() { if (!$this->video_duration) return '--:--'; $minutes = floor($this->video_duration / 60); $seconds = $this->video_duration % 60; return sprintf('%02d:%02d', $minutes, $seconds); }

    public function scopePublished($query) { return $query->where('is_published', true); }
}
