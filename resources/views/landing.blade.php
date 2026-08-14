<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Together We Can - Application communautaire</title>
    <meta name="description" content="Together We Can est une application communautaire : réseau social, marketplace, formations en ligne, promotion sur réseaux sociaux et portefeuille mobile money.">
    <link rel="icon" href="{{ asset('logo.png') }}">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0B0B0B;
            color: #FFFFFF;
            line-height: 1.6;
        }
        .container { max-width: 1000px; margin: 0 auto; padding: 0 24px; }
        header {
            padding: 60px 24px 40px;
            text-align: center;
            background: linear-gradient(180deg, #0F1F17 0%, #0B0B0B 100%);
        }
        header img { width: 100px; height: 100px; margin-bottom: 16px; }
        header h1 { font-size: 2.4rem; color: #00A86B; font-weight: 700; }
        header p { color: #AAAAAA; font-size: 1.1rem; margin-top: 10px; max-width: 560px; margin-left: auto; margin-right: auto; }
        .btn {
            display: inline-block;
            background: #00A86B;
            color: white;
            padding: 14px 32px;
            border-radius: 50px;
            font-weight: bold;
            text-decoration: none;
            margin-top: 24px;
            transition: 0.2s;
        }
        .btn:hover { background: #008C5A; }
        section { padding: 50px 24px; }
        section h2 { font-size: 1.6rem; margin-bottom: 24px; color: #FFFFFF; text-align: center; }
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .feature {
            background: #161616;
            border: 1px solid #232323;
            border-radius: 14px;
            padding: 24px;
        }
        .feature .emoji { font-size: 2rem; margin-bottom: 8px; }
        .feature h3 { color: #00A86B; font-size: 1.05rem; margin-bottom: 6px; }
        .feature p { color: #999; font-size: 0.9rem; }
        .about { background: #111; }
        .about p { color: #ccc; max-width: 700px; margin: 0 auto; text-align: center; }
        footer {
            padding: 30px 24px;
            text-align: center;
            border-top: 1px solid #1E1E1E;
            color: #666;
            font-size: 0.85rem;
        }
        footer a { color: #00A86B; text-decoration: none; margin: 0 10px; }
        footer a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <header>
        <img src="{{ asset('logo.png') }}" alt="Together We Can">
        <h1>Together We Can</h1>
        <p>La plateforme communautaire qui réunit réseau social, marketplace, formations, promotion sur les réseaux sociaux et portefeuille mobile money en une seule application.</p>
        <a href="https://www.mediafire.com/file/7pbzp4kg1icsb7k/Together_.apk/file" class="btn">📱 Télécharger l'application</a>
    </header>

    <section>
        <div class="container">
            <h2>Ce que propose l'application</h2>
            <div class="features">
                <div class="feature">
                    <div class="emoji">📱</div>
                    <h3>Réseau social</h3>
                    <p>Fil d'actualité, publications, stories, messagerie privée entre membres de la communauté.</p>
                </div>
                <div class="feature">
                    <div class="emoji">🛒</div>
                    <h3>Marketplace</h3>
                    <p>Achetez et vendez des produits directement entre utilisateurs, avec avis et favoris.</p>
                </div>
                <div class="feature">
                    <div class="emoji">📚</div>
                    <h3>Formations</h3>
                    <p>Catalogue de cours en ligne, gratuits et payants, avec suivi de progression.</p>
                </div>
                <div class="feature">
                    <div class="emoji">🚀</div>
                    <h3>Clic-Boost</h3>
                    <p>Services de promotion (vues, abonnés, likes) sur les principaux réseaux sociaux.</p>
                </div>
                <div class="feature">
                    <div class="emoji">💰</div>
                    <h3>Portefeuille</h3>
                    <p>Dépôt et retrait via Mobile Money, transferts entre utilisateurs, historique complet.</p>
                </div>
                <div class="feature">
                    <div class="emoji">🎁</div>
                    <h3>Parrainage</h3>
                    <p>Programme de parrainage récompensant les utilisateurs qui font grandir la communauté.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="about">
        <div class="container">
            <h2>À propos</h2>
            <p>
                Together We Can est développée pour offrir à sa communauté un espace unique combinant
                réseau social, commerce en ligne et services financiers mobiles. L'application est disponible
                pour Android via téléchargement direct, en attendant sa publication sur le Play Store.
            </p>
        </div>
    </section>

    <footer>
        <div>
            <a href="/terms">Conditions d'utilisation</a>
            <a href="/privacy">Politique de confidentialité</a>
            <a href="mailto:jephbesaus07@gmail.com">Contact</a>
        </div>
        <div style="margin-top: 12px;">© {{ date('Y') }} Together We Can. Tous droits réservés.</div>
    </footer>
</body>
</html>
