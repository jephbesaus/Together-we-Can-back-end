-- Create or update the administrator in PostgreSQL.
-- Run with:
-- psql "$DB_URL" --set=admin_email='admin@example.com' --set=admin_phone='+243000000000' --set=admin_password='CHOOSE_A_STRONG_PASSWORD' -f database/admin.sql
--
-- The password is intentionally supplied at execution time and is never committed.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO users (
    name,
    email,
    phone,
    password,
    role,
    is_admin_activated,
    is_verified,
    created_at,
    updated_at
)
VALUES (
    'Together We Can Admin',
    :'admin_email',
    :'admin_phone',
    crypt(:'admin_password', gen_salt('bf', 12)),
    'admin',
    TRUE,
    TRUE,
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    password = EXCLUDED.password,
    role = 'admin',
    is_admin_activated = TRUE,
    is_verified = TRUE,
    updated_at = NOW();
