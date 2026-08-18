# Plan: 6 Remaining Items

## 1. Logo — taille augmentée
**Fichier:** `twc-flutter/lib/screens/splash/splash_screen.dart`

- Container blanc: 220x220 → **280x280**
- Padding interne: 30 → **35**
- Logo image: ~160x160 → **~210x210**
- Même changement dans `login_screen.dart`, `register_screen.dart`, `discover_screen.dart`, `about_screen.dart`

## 2. Formulaire paiement manuel — Nom + Prénom + ID
**Fichiers:** `wallet_screen.dart`, `TransactionController.php`

### Flutter (wallet_screen.dart)
Le formulaire manuel doit afficher:
- **Nom** (text field)
- **Prénom** (text field)
- **ID de la transaction** (text field)
- **Montant** (number field)
- **Opérateur** (dropdown)
- Bouton **"Finaliser le paiement"** → submit
- Message: "Votre paiement est en attente de validation par l'administrateur"

### Backend (TransactionController.php — manualDeposit())
Ajouter validation:
- `last_name` (required|string)
- `first_name` (required|string)
- Stocker dans metadata: `{ manual: true, chariow_reference, provider, last_name, first_name }`

## 3. Faux soldes — CORRECTION CRITIQUE
**Problème:** Race condition entre `balance()` auto-complete et `checkChariowStatus()` → double crédit.

### Fix 1: PaymentService.php — checkChariowStatus()
Ajouter filtre pour exclure les deposits manuels:
```php
->whereRaw("metadata->>'manual' IS DISTINCT FROM 'true'")
```

### Fix 2: TransactionController.php — balance()
Ajouter `lockForUpdate()` ou utiliser update atomique:
```php
DB::transaction(function () use ($pending, $user) {
    foreach ($pending as $tx) {
        $updated = Transaction::where('id', $tx->id)
            ->where('status', 'pending')
            ->update(['status' => 'completed', 'completed_at' => now()]);
        if ($updated) {
            $user->increment('boost_balance', $tx->amount);
        }
    }
});
```

### Fix 3: PaymentService.php — checkChariowStatus()
Même pattern atomique:
```php
$updated = Transaction::where('id', $transaction->id)
    ->where('status', 'pending')
    ->update(['status' => 'completed', 'completed_at' => now()]);
if ($updated) {
    $user->increment('boost_balance', $transaction->amount);
}
```

## 4. Notifications en arrière-plan
**Fichiers:** `fcm_service.dart`, `main.dart`

### Ajouter un handler top-level:
```dart
// fcm_background_handler.dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Les notifications système sont gérées par FCM automatiquement
}
```

### Enregistrer dans main.dart:
```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```
Avant `runApp()`.

## 5. Lien de support — dynamique
**Fichiers:** `support_screen.dart`, `InfoController.php`

### Backend: GET /support existe déjà (InfoController.php)
Vérifie que le endpoint retourne bien les URLs depuis `config/support.php`.

### Flutter: support_screen.dart
Remplacer les valeurs hardcodées par un appel API:
```dart
final response = await _api.get('/support');
// Utiliser response['data'] pour les URLs
```

## 6. Image formations admin — DÉJÀ FAIT ✅
`admin_payments_screen.dart` a déjà l'upload d'image + CachedNetworkImage display.

---

## Fichiers à modifier

| Fichier | Changement |
|---------|-----------|
| `twc-flutter/lib/screens/splash/splash_screen.dart` | Logo 280x280 |
| `twc-flutter/lib/screens/auth/login_screen.dart` | Logo taille |
| `twc-flutter/lib/screens/auth/register_screen.dart` | Logo taille |
| `twc-flutter/lib/screens/discover/discover_screen.dart` | Logo taille |
| `twc-flutter/lib/screens/menu/about_screen.dart` | Logo taille |
| `twc-flutter/lib/screens/wallet/wallet_screen.dart` | Formulaire manuel: Nom + Prénom |
| `app/Http/Controllers/Api/TransactionController.php` | manualDeposit: +last_name +first_name, balance: atomique |
| `app/Services/PaymentService.php` | checkChariowStatus: exclure manuels + atomique |
| `twc-flutter/lib/core/services/fcm_service.dart` | Export background handler |
| `twc-flutter/lib/main.dart` | Register background handler |
| `twc-flutter/lib/screens/menu/support_screen.dart` | Fetch URLs from API |
