<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Course extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'instructor_id', 'title', 'description', 'cover_image', 'category',
        'level', 'price', 'is_free', 'is_published', 'featured',
        'duration_minutes', 'lessons_count', 'students_count', 'rating',
        'reviews_count', 'what_you_will_learn', 'requirements', 'target_audience'
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_free' => 'boolean',
        'is_published' => 'boolean',
        'featured' => 'boolean',
        'rating' => 'decimal:2',
        'what_you_will_learn' => 'array',
        'requirements' => 'array',
        'target_audience' => 'array',
    ];

    protected $appends = ['formatted_price', 'is_enrolled', 'progress', 'level_label', 'formatted_duration'];

    const LEVEL_BEGINNER = 'beginner';
    const LEVEL_INTERMEDIATE = 'intermediate';
    const LEVEL_ADVANCED = 'advanced';
    const LEVEL_EXPERT = 'expert';
    const LEVEL_LABELS = ['beginner' => 'Débutant', 'intermediate' => 'Intermédiaire', 'advanced' => 'Avancé', 'expert' => 'Expert'];

    public function instructor() { return $this->belongsTo(User::class, 'instructor_id'); }
    public function lessons() { return $this->hasMany(CourseLesson::class)->orderBy('order_position', 'asc'); }
    public function enrollments() { return $this->hasMany(CourseEnrollment::class); }
    public function reviews() { return $this->hasMany(CourseReview::class); }
    public function sections() { return $this->hasMany(CourseSection::class)->orderBy('order_position', 'asc'); }

    public function getFormattedPriceAttribute() { return $this->is_free ? 'Gratuit' : number_format($this->price, 0, ',', ' ') . ' FCFA'; }
    public function getIsEnrolledAttribute() { if (!auth()->check()) return false; return $this->enrollments()->where('user_id', auth()->id())->exists(); }
    public function getProgressAttribute() { if (!auth()->check()) return 0; $enrollment = $this->enrollments()->where('user_id', auth()->id())->first(); return $enrollment ? $enrollment->progress : 0; }
    public function getLevelLabelAttribute() { return self::LEVEL_LABELS[$this->level] ?? $this->level; }
    public function getFormattedDurationAttribute() { $hours = floor($this->duration_minutes / 60); $minutes = $this->duration_minutes % 60; if ($hours > 0) return $hours . 'h ' . $minutes . 'min'; return $minutes . 'min'; }

    public function scopePublished($query) { return $query->where('is_published', true); }
    public function scopeFree($query) { return $query->where('is_free', true); }
    public function scopeFeatured($query) { return $query->where('featured', true); }
    public function scopeSearch($query, $term) { return $query->where(function ($q) use ($term) { $q->where('title', 'LIKE', "%{$term}%")->orWhere('description', 'LIKE', "%{$term}%")->orWhere('category', 'LIKE', "%{$term}%"); }); }

    public function incrementStudents() { $this->increment('students_count'); }
    public function updateRating() { $avg = $this->reviews()->avg('rating') ?? 0; $count = $this->reviews()->count(); $this->update(['rating' => round($avg, 1), 'reviews_count' => $count]); }
}
