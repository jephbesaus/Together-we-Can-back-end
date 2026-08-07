<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Together We Can</title>
</head>
<body style="margin:0;padding:0;background:#0B0B0B;font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 0;">
        <tr>
            <td align="center">
                <table width="480" cellpadding="0" cellspacing="0" style="background:#161616;border-radius:12px;overflow:hidden;">
                    <tr>
                        <td style="background:#00A86B;padding:24px;text-align:center;">
                            <h1 style="color:#fff;margin:0;font-size:22px;">Together We Can</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:32px;color:#fff;">
                            <p style="font-size:16px;">Bonjour {{ $userName }},</p>
                            <p style="font-size:15px;color:#ccc;">Voici votre code de vérification :</p>
                            <div style="text-align:center;margin:24px 0;">
                                <span style="display:inline-block;background:#000;color:#00A86B;font-size:32px;letter-spacing:8px;font-weight:bold;padding:16px 24px;border-radius:8px;">
                                    {{ $otp }}
                                </span>
                            </div>
                            <p style="font-size:13px;color:#888;">Ce code expire dans quelques minutes. Ne le partagez avec personne.</p>
                            <p style="font-size:13px;color:#888;">Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:16px;text-align:center;color:#555;font-size:11px;">
                            © {{ date('Y') }} Together We Can
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
