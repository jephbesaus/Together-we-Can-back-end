<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $otp;
    public string $userName;
    public string $purpose;

    public function __construct(string $otp, string $userName, string $purpose = 'verification')
    {
        $this->otp = $otp;
        $this->userName = $userName;
        $this->purpose = $purpose;
    }

    public function envelope(): Envelope
    {
        $subjects = [
            'verification' => 'Confirmez votre inscription - Together We Can',
            'reset' => 'Réinitialisation de mot de passe - Together We Can',
            'resend' => 'Votre nouveau code - Together We Can',
        ];

        return new Envelope(
            subject: $subjects[$this->purpose] ?? 'Votre code de vérification - Together We Can',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.otp',
        );
    }
}
