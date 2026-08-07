# Together-we-Can-back-end

Backend Laravel API for Together We Can.

## Local Docker

```bash
docker compose up -d
```

The API is available at `http://localhost:8083`.
The administration dashboard is available at `http://localhost:8083/admin/`.

## Render

This repository includes `render.yaml`. Create a Blueprint from the repository,
then set `APP_URL`, `FRONTEND_URL`, `ADMIN_EMAIL`, and `ADMIN_ACTIVATION_CODE`
in the Render environment variables.

After the first deployment, create the admin account with:

```bash
psql "$DB_URL" \
  --set=admin_email='admin@example.com' \
  --set=admin_phone='+243000000000' \
  --set=admin_password='CHOOSE_A_STRONG_PASSWORD' \
  -f database/admin.sql
```
