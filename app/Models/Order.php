<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, SoftDeletes;

    const STATUS_PENDING = 'pending';
    const STATUS_CONFIRMED = 'confirmed';
    const STATUS_PROCESSING = 'processing';
    const STATUS_SHIPPED = 'shipped';
    const STATUS_DELIVERED = 'delivered';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_REFUNDED = 'refunded';

    const STATUS_LABELS = [
        'pending' => 'En attente', 'confirmed' => 'Confirmée',
        'processing' => 'En traitement', 'shipped' => 'Expédiée',
        'delivered' => 'Livrée', 'completed' => 'Terminée',
        'cancelled' => 'Annulée', 'refunded' => 'Remboursée'
    ];

    const STATUS_COLORS = [
        'pending' => '#FF9800', 'confirmed' => '#2196F3',
        'processing' => '#9C27B0', 'shipped' => '#00BCD4',
        'delivered' => '#4CAF50', 'completed' => '#8BC34A',
        'cancelled' => '#F44336', 'refunded' => '#9E9E9E'
    ];

    protected $fillable = [
        'product_id', 'buyer_id', 'seller_id', 'quantity', 'total_price',
        'status', 'shipping_address', 'tracking_info', 'delivery_date',
        'notes', 'payment_method', 'payment_reference', 'is_paid', 'paid_at'
    ];

    protected $casts = [
        'quantity' => 'integer',
        'total_price' => 'decimal:2',
        'is_paid' => 'boolean',
        'delivery_date' => 'datetime',
        'paid_at' => 'datetime',
    ];

    protected $appends = ['status_label', 'status_color', 'formatted_total'];

    public function product() { return $this->belongsTo(Product::class); }
    public function buyer() { return $this->belongsTo(User::class, 'buyer_id'); }
    public function seller() { return $this->belongsTo(User::class, 'seller_id'); }

    public function getStatusLabelAttribute() { return self::STATUS_LABELS[$this->status] ?? $this->status; }
    public function getStatusColorAttribute() { return self::STATUS_COLORS[$this->status] ?? '#9E9E9E'; }
    public function getFormattedTotalAttribute() { return number_format($this->total_price, 0, ',', ' ') . ' FCFA'; }

    public function scopePending($query) { return $query->where('status', 'pending'); }
    public function scopeActive($query) { return $query->whereNotIn('status', ['cancelled', 'completed', 'refunded']); }
    public function scopeForUser($query, $userId) { return $query->where('buyer_id', $userId)->orWhere('seller_id', $userId); }
}
