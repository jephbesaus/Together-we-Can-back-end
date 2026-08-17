<?php

namespace App\Services;

use App\Models\CourseEnrollment;
use App\Models\Course;
use App\Models\User;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CertificateService
{
    public function generateCertificate(CourseEnrollment $enrollment)
    {
        if ($enrollment->progress < 100) {
            return null;
        }

        if ($enrollment->certificate_url && $enrollment->certificate_id) {
            return [
                'certificate_url' => $enrollment->certificate_url,
                'certificate_id' => $enrollment->certificate_id,
            ];
        }

        $course = Course::find($enrollment->course_id);
        $user = User::find($enrollment->user_id);

        if (!$course || !$user) {
            return null;
        }

        $certificateId = 'TWC-' . strtoupper(Str::random(8)) . '-' . date('Ymd');

        $html = $this->buildCertificateHtml($user, $course, $certificateId, $enrollment->completed_at);

        $filename = 'certificates/' . $certificateId . '.html';
        Storage::disk('public')->put($filename, $html);

        $certificateUrl = Storage::url($filename);

        $enrollment->update([
            'certificate_url' => $certificateUrl,
            'certificate_id' => $certificateId,
        ]);

        return [
            'certificate_url' => $certificateUrl,
            'certificate_id' => $certificateId,
        ];
    }

    public function getCertificate(CourseEnrollment $enrollment)
    {
        if ($enrollment->certificate_url && $enrollment->certificate_id) {
            return [
                'certificate_url' => $enrollment->certificate_url,
                'certificate_id' => $enrollment->certificate_id,
            ];
        }

        if ($enrollment->progress >= 100) {
            return $this->generateCertificate($enrollment);
        }

        return null;
    }

    private function buildCertificateHtml($user, $course, $certificateId, $completedAt)
    {
        $date = $completedAt ? $completedAt->format('d/m/Y') : now()->format('d/m/Y');

        return '<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Certificat - Together We Can</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            background: #f0f2f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
        }
        .certificate {
            background: white;
            width: 800px;
            padding: 60px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            text-align: center;
            position: relative;
            border: 3px solid #1a73e8;
        }
        .certificate::before {
            content: "";
            position: absolute;
            top: 10px; left: 10px; right: 10px; bottom: 10px;
            border: 1px solid #1a73e8;
            border-radius: 8px;
            pointer-events: none;
        }
        .logo {
            font-size: 32px;
            font-weight: 800;
            color: #1a73e8;
            margin-bottom: 10px;
            letter-spacing: 2px;
        }
        .subtitle {
            font-size: 14px;
            color: #666;
            margin-bottom: 40px;
            text-transform: uppercase;
            letter-spacing: 3px;
        }
        .title {
            font-size: 28px;
            color: #333;
            margin-bottom: 10px;
            font-weight: 300;
        }
        .presented-to {
            font-size: 16px;
            color: #666;
            margin-bottom: 15px;
        }
        .name {
            font-size: 36px;
            font-weight: 700;
            color: #1a73e8;
            margin-bottom: 20px;
            border-bottom: 2px solid #1a73e8;
            display: inline-block;
            padding-bottom: 5px;
        }
        .description {
            font-size: 16px;
            color: #555;
            margin-bottom: 10px;
        }
        .course-name {
            font-size: 22px;
            font-weight: 600;
            color: #333;
            margin-bottom: 30px;
        }
        .details {
            display: flex;
            justify-content: space-between;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
        .detail {
            text-align: center;
        }
        .detail-label {
            font-size: 12px;
            color: #999;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .detail-value {
            font-size: 14px;
            color: #333;
            margin-top: 5px;
            font-weight: 600;
        }
        .footer {
            margin-top: 30px;
            font-size: 12px;
            color: #999;
        }
    </style>
</head>
<body>
    <div class="certificate">
        <div class="logo">TOGETHER WE CAN</div>
        <div class="subtitle">Certificat de Réussite</div>

        <div class="title">Ce certificat est délivré à</div>
        <div class="name">' . htmlspecialchars($user->name) . '</div>

        <div class="description">pour avoir complété avec succès la formation</div>
        <div class="course-name">' . htmlspecialchars($course->title) . '</div>

        <div class="details">
            <div class="detail">
                <div class="detail-label">Date de délivrance</div>
                <div class="detail-value">' . $date . '</div>
            </div>
            <div class="detail">
                <div class="detail-label">Identifiant</div>
                <div class="detail-value">' . $certificateId . '</div>
            </div>
            <div class="detail">
                <div class="detail-label">Durée</div>
                <div class="detail-value">' . $course->formatted_duration . '</div>
            </div>
        </div>

        <div class="footer">
            Together We Can — Plateforme communautaire d\'apprentissage
        </div>
    </div>
</body>
</html>';
    }
}
