<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class BoostOrder extends Model
{
    use HasFactory, SoftDeletes;

    const STATUS_PENDING = 'pending';
    const STATUS_PROCESSING = 'processing';
    const STATUS_COMPLETED = 'completed';
    const STATUS_PARTIAL = 'partial';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_FAILED = 'failed';
    const STATUS_REFILLED = 'refilled';

    const STATUS_LABELS = [
        'pending' => 'En attente', 'processing' => 'En cours',
        'completed' => 'Terminée', 'partial' => 'Partielle',
        'cancelled' => 'Annulée', 'failed' => 'Échouée', 'refilled' => 'Remplie'
    ];

    const STATUS_COLORS = [
        'pending' => '#FF9800', 'processing' => '#2196F3',
        'completed' => '#4CAF50', 'partial' => '#9C27B0',
        'cancelled' => '#F44336', 'failed' => '#F44336', 'refilled' => '#00BCD4'
    ];

    protected $fillable = [
        'user_id', 'platform', 'service_id', 'service_name', 'service_category',
        'link', 'quantity', 'price', 'price_per_unit', 'fullsmm_order_id',
        'status', 'status_message', 'started_at', 'completed_at', 'remaining', 'refill_status'
    ];

    protected $casts = [
        'quantity' => 'integer',
        'price' => 'decimal:2',
        'price_per_unit' => 'decimal:4',
        'remaining' => 'integer',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    protected $appends = ['status_label', 'status_color', 'formatted_price', 'platform_icon'];

    public function user() { return $this->belongsTo(User::class); }

    public function getStatusLabelAttribute() { return self::STATUS_LABELS[$this->status] ?? $this->status; }
    public function getStatusColorAttribute() { return self::STATUS_COLORS[$this->status] ?? '#9E9E9E'; }
    public function getFormattedPriceAttribute() { return number_format($this->price, 0, ',', ' ') . ' FCFA'; }
    public function getPlatformIconAttribute() { $platforms = config('fullsmm.platforms', []); return $platforms[$this->platform]['icon'] ?? 'globe'; }

    public function scopePending($query) { return $query->where('status', 'pending'); }
    public function scopeProcessing($query) { return $query->where('status', 'processing'); }
    public function scopeCompleted($query) { return $query->where('status', 'completed'); }
    public function scopeForUser($query, $userId) { return $query->where('user_id', $userId); }

    public function isComplete() { return in_array($this->status, ['completed', 'refilled']); }
    public function isProcessing() { return in_array($this->status, ['pending', 'processing', 'partial']); }
    public function isFailed() { return in_array($this->status, ['cancelled', 'failed']); }
}
