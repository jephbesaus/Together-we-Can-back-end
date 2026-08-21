<?php

return [

    // Lien API de l'application FusionPay (moneyfusion.net) — disponible
    // dans le dashboard FusionPay > API de paiement > Application.
    'api_url' => env('FUSIONPAY_API_URL'),

    'api_key' => env('FUSIONPAY_API_KEY'),

    // Endpoint public de vérification du statut d'un paiement par token.
    'status_base_url' => env('FUSIONPAY_STATUS_URL', 'https://www.pay.moneyfusion.net/paiementNotif'),

];
