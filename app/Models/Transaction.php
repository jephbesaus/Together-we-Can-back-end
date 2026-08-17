<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Transaction extends Model
{
    use HasFactory, SoftDeletes;

    const TYPE_DEPOSIT = 'deposit';
    const TYPE_WITHDRAWAL = 'withdrawal';
    const TYPE_BOOST_PAYMENT = 'boost_payment';
    const TYPE_MARKETPLACE_PAYMENT = 'marketplace_payment';
    const TYPE_COURSE_PAYMENT = 'course_payment';
    const TYPE_SAVINGS = 'savings';
    const TYPE_TRANSFER_SENT = 'transfer_sent';
    const TYPE_TRANSFER_RECEIVED = 'transfer_received';
    const TYPE_REFUND = 'refund';

    const STATUS_PENDING = 'pending';
    const STATUS_COMPLETED = 'completed';
    const STATUS_FAILED = 'failed';
    const STATUS_REFUNDED = 'refunded';

    protected $fillable = [
        'user_id', 'type', 'amount', 'fee', 'reference', 'payment_method',
        'status', 'description', 'metadata', 'completed_at'
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'fee' => 'decimal:2',
        'metadata' => 'array',
        'completed_at' => 'datetime',
    ];

    protected $appends = ['type_label', 'status_label', 'status_color', 'formatted_amount'];

    public function user() { return $this->belongsTo(User::class); }

    public function getTypeLabelAttribute()
    {
        $labels = [
            'deposit' => 'Dépôt', 'withdrawal' => 'Retrait',
            'boost_payment' => 'Achat Boost', 'marketplace_payment' => 'Achat Marketplace',
            'course_payment' => 'Achat Formation', 'savings' => 'Épargne',
            'transfer_sent' => 'Transfert envoyé', 'transfer_received' => 'Transfert reçu',
            'refund' => 'Remboursement'
        ];
        return $labels[$this->type] ?? $this->type;
    }

    public function getStatusLabelAttribute()
    {
        $labels = ['pending' => 'En attente', 'completed' => 'Terminé', 'failed' => 'Échoué', 'refunded' => 'Remboursé'];
        return $labels[$this->status] ?? $this->status;
    }

    public function getStatusColorAttribute()
    {
        $colors = ['pending' => '#FF9800', 'completed' => '#4CAF50', 'failed' => '#F44336', 'refunded' => '#9E9E9E'];
        return $colors[$this->status] ?? '#9E9E9E';
    }

    public function getFormattedAmountAttribute()
    {
        $prefix = in_array($this->type, ['withdrawal', 'boost_payment', 'marketplace_payment', 'course_payment', 'transfer_sent']) ? '- ' : '+ ';
        return $prefix . number_format($this->amount, 0, ',', ' ') . ' CDF';
    }

    public function scopePending($query) { return $query->where('status', 'pending'); }
    public function scopeCompleted($query) { return $query->where('status', 'completed'); }
    public function scopeForUser($query, $userId) { return $query->where('user_id', $userId); }
}
