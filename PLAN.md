# Plan: Fix Chariow Payment Redirect

## Root Cause

The Chariow API requires `redirect_url` to be a **valid HTTPS URL** (per their docs: "Must be a valid active URL. Example: `https://yoursite.com/thank-you`"). Two bugs exist:

1. **Wallet deposit** sends `redirect_url` = `https://epazzsvw.mychariow.store/thank-you` — a dead-end Chariow store page. User has no way back to the app.
2. **Course payment** sends `redirect_url` = `twc://payment?courseId=X` — a custom URI scheme that Chariow rejects/ignores since it's not HTTPS.
3. **No app resume listener** — neither screen refreshes when user manually returns.

## Fix (6 changes)

### 1. Backend — `PaymentService.php` (2 edits)

**Lines 58 (deposit) and 260 (course):** Change `redirect_url` to point to a new `/thank-you` page on our backend that bridges to the app:

```
// Deposit:
'redirect_url' => url('/thank-you?reference=' . $reference . '&type=deposit')

// Course:
'redirect_url' => url('/thank-you?reference=' . $reference . '&type=course&courseId=' . $courseId)
```

### 2. Backend — `routes/web.php` (1 addition)

Add `/thank-you` route that renders an HTML page with:
- Auto-redirects to `twc://payment?reference=...&type=...` via JavaScript
- Fallback "Ouvrir l'app" button
- Auto-closes after 3 seconds

### 3. Flutter — `wallet_screen.dart` (1 edit)

Add `WidgetsBindingObserver` to `_WalletScreenState`:
- Implement `didChangeAppLifecycleState(AppLifecycleState.resumed)` → call `_loadData()`
- Add/remove observer in `initState`/`dispose`

### 4. Flutter — `course_detail_screen.dart` (1 edit)

Same `WidgetsBindingObserver` pattern:
- On resume → call `_loadCourse()` and re-check enrollment status

### 5. Flutter — `deep_link_service.dart` (1 edit)

Update `_handleUri` to handle deposit returns:
- `twc://payment?reference=...&type=deposit` → navigate to `/wallet` (or just dismiss, since wallet screen will refresh on resume)
- `twc://payment?reference=...&type=course&courseId=...` → navigate to `/course-detail`

### 6. Flutter — `AndroidManifest.xml` (1 edit)

Remove `android:autoVerify="true"` from the deep link intent filter — it's incorrect for custom URI schemes and may cause Android to ignore the filter.

## Files to modify

| File | Change |
|------|--------|
| `app/Services/PaymentService.php` | Lines 58, 260 — fix redirect_url |
| `routes/web.php` | Add `/thank-you` route |
| `twc-flutter/lib/screens/wallet/wallet_screen.dart` | Add WidgetsBindingObserver |
| `twc-flutter/lib/screens/courses/course_detail_screen.dart` | Add WidgetsBindingObserver |
| `twc-flutter/lib/core/services/deep_link_service.dart` | Handle deposit deep link |
| `twc-flutter/android/app/src/main/AndroidManifest.xml` | Remove autoVerify |

## Verification

1. Deploy backend, test `/thank-you?reference=test&type=deposit` in browser — should show page that attempts `twc://` redirect
2. On device: initiate deposit → pay on Chariow → should redirect to thank-you page → should auto-redirect back to app
3. On device: wallet balance should refresh automatically when user returns
4. Same flow for course payment
