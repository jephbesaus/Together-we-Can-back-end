<?php

return [

    'project_id' => env('FIREBASE_PROJECT_ID'),

    'credentials' => [
        'file' => env('FIREBASE_CREDENTIALS', storage_path('app/firebase/service-account.json')),
    ],

];
