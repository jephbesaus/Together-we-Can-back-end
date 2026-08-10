<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }} - Together We Can</title>
    <link rel="icon" href="{{ asset('logo.png') }}">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0B0B0B;
            color: #DDDDDD;
            line-height: 1.7;
        }
        .container { max-width: 760px; margin: 0 auto; padding: 40px 24px 60px; }
        a.back { color: #00A86B; text-decoration: none; font-size: 0.9rem; }
        h1 { color: #FFFFFF; font-size: 1.8rem; margin: 20px 0 24px; }
        h2 { color: #00A86B; font-size: 1.1rem; margin: 24px 0 8px; }
        p { color: #bbb; margin-bottom: 8px; white-space: pre-line; }
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back">&larr; Retour à l'accueil</a>
        <h1>{{ $title }}</h1>
        @yield('content')
    </div>
</body>
</html>
