# Plan: Système de vérification manuelle des paiements

## Concept
L'utilisateur paie sur Chariow (navigateur) → récupère l'ID de transaction → le colle dans l'app → le paiement reste "en attente" → l'admin vérifie → approuve ou rejette → si approuvé → crédit au compte.

## Flow détaillé

```
1. User tape "Déposer" → entre le montant → choisit "Paiement manuel"
2. App affiche: "Payez {montant} CDF sur Chariow. Collez votre ID ci-dessous."
3. User paie sur Chariow (navigateur) → récupère l'ID
4. User revient dans l'app → colle l'ID → tape "Soumettre"
5. Backend crée une Transaction (status: pending, type: deposit)
   metadata: { manual: true, chariow_reference: "...", provider: "...", submitted_at: "..." }
6. Admin voit la demande dans son panneau → vérifie sur Chariow
7. Admin approuve → backend crédite le boost_balance + notifie l'utilisateur
   Admin rejette → backend notifie l'utilisateur du rejet
```

## Fichiers à modifier/créer

### Backend (6 fichiers)

| Fichier | Changement |
|---------|-----------|
| `app/Http/Controllers/Api/TransactionController.php` | Nouvelle méthode `manualDeposit()` — reçoit amount + reference + provider, crée transaction pending |
| `app/Http/Controllers/Api/AdminController.php` | 3 nouvelles méthodes: `pendingPayments()`, `approvePayment()`, `rejectPayment()` |
| `routes/api.php` | 2 nouvelles routes user + 3 nouvelles routes admin |
| `app/Http/Middleware/AdminMiddleware.php` | Aucun changement (déjà OK) |
| `app/Services/PaymentService.php` | Aucun changement — on ne touche pas à l'auto-complete existant, on l'a juste désactivé pour les deposits manuels via metadata flag |
| `app/Models/Transaction.php` | Ajouter constante `STATUS_PENDING_REVIEW` OU utiliser `pending` + `metadata['manual'] = true` |

### Flutter (4 fichiers)

| Fichier | Changement |
|---------|-----------|
| `twc-flutter/lib/screens/wallet/wallet_screen.dart` | Ajouter option "Paiement manuel" dans le dialog de dépôt |
| `twc-flutter/lib/screens/admin/admin_payments_screen.dart` | **Nouveau** — liste des paiements en attente, approuver/rejeter |
| `twc-flutter/lib/screens/admin/admin_dashboard_screen.dart` | Ajouter tile "Paiements" + import |
| `twc-flutter/lib/app/routes.dart` | Ajouter route `/admin/payments` |

## Backend détaillé

### 1. `TransactionController::manualDeposit()`
```
POST /transactions/manual-deposit
Body: { amount, reference, provider }

- Valider: amount >= 500, reference non vide, provider dans la liste
- Créer Transaction:
  - user_id: auth()->id()
  - type: 'deposit'
  - amount: $amount
  - reference: 'MAN-DEP-' . Str::random(16)
  - payment_method: 'manual_' . $provider
  - status: 'pending'
  - metadata: { manual: true, chariow_reference: $reference, provider: $provider, submitted_at: now() }
  - description: 'Dépôt manuel via ' . $provider
- Retourner: success + transaction
```

### 2. `AdminController::pendingPayments()`
```
GET /admin/payments?status=pending

- Lister les Transactions où type='deposit' ET metadata->manual = true
- Filtrer par status (pending/completed/failed)
- Inclure le user (name, email)
- Trier par created_at DESC
```

### 3. `AdminController::approvePayment()`
```
POST /admin/payments/{id}/approve

- Trouver la transaction (doit être pending + metadata.manual = true)
- update status → completed, completed_at → now()
- increment user boost_balance
- Créer notification: "Votre dépôt de {amount} CDF a été approuvé."
- Retourner success
```

### 4. `AdminController::rejectPayment()`
```
POST /admin/payments/{id}/reject
Body: { reason } (optionnel)

- Trouver la transaction
- update status → failed
- update metadata: add rejected_reason, rejected_at
- Créer notification: "Votre dépôt de {amount} CDF a été rejeté. Raison: {reason}"
- Retourner success
```

### Routes à ajouter (api.php)
```php
// User routes (dans le groupe auth:sanctum)
Route::post('/transactions/manual-deposit', [TransactionController::class, 'manualDeposit']);

// Admin routes (dans le groupe admin)
Route::get('/admin/payments', [AdminController::class, 'pendingPayments']);
Route::post('/admin/payments/{id}/approve', [AdminController::class, 'approvePayment']);
Route::post('/admin/payments/{id}/reject', [AdminController::class, 'rejectPayment']);
```

## Flutter détaillé

### 1. `wallet_screen.dart` — Dialog de dépôt modifié
Ajouter un toggle "Paiement rapide (Chariow)" / "Paiement manuel":
- **Rapide**: flow actuel (ouvre Chariow dans le navigateur)
- **Manuel**: affiche un champ "ID de transaction Chariow" + dropdown opérateur
  - User paie sur Chariow séparément
  - Colle l'ID ici
  - Appelle `POST /transactions/manual-deposit`

### 2. `admin_payments_screen.dart` — Nouveau
```
- Liste des paiements manuels en attente
- Chaque item affiche: nom user, montant, provider, date, ID Chariow
- Swipe ou boutons: Approuver (vert) / Rejeter (rouge)
- Filtre: En attente / Approuvés / Rejetés
- Tap pour détails: montant, email, référence Chariow, date soumission
```

### 3. `admin_dashboard_screen.dart` — Tile ajoutée
```dart
_buildQuickAction(Icons.payment, 'Paiements', () => Get.to(() => const AdminPaymentsScreen())),
```

## Auto-complete: que faire ?
L'auto-complete de 1 minute (`TransactionController::balance()` + `PaymentService::checkChariowStatus()`) auto-valide TOUT pending deposit après 1 minute.

**Solution:** Modifier l'auto-complete pour exclure les deposits manuels:
```php
// Avant:
->where('type', 'deposit')
->where('status', 'pending')

// Après:
->where('type', 'deposit')
->where('status', 'pending')
->whereRaw("metadata->>'manual' IS NULL OR metadata->>'manual' != 'true'")
```

## Vérification
1. Tester le endpoint `POST /transactions/manual-deposit` avec curl
2. Vérifier que la transaction apparaît dans `GET /admin/payments`
3. Tester approve/reject
4. Vérifier que l'auto-complete NE touche PAS aux deposits manuels
5. Tester le flow complet dans l'app (wallet → manuel → admin → approuver)
