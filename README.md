# RYDEX

RYDEX is a Kenyan ride-hailing platform with Passenger, Driver and Admin apps.

## Stack
- Backend: FastAPI + SQLAlchemy + JWT
- Database: SQLite by default; PostgreSQL supported through DATABASE_URL
- Mobile: Flutter
- Authentication: OAuth2 password flow
- Roles: passenger, driver, admin

## Backend setup on Fedora

```bash
cd ~/Projects
unzip RYDEX.zip
cd RYDEX/backend

python3 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
cp .env.example .env

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Swagger:
http://127.0.0.1:8000/docs

The default database is `rydex.db`, which is intentionally easy to reset during development.

## Important
For a physical Android phone, replace the API URL in each Flutter app with the Fedora computer's LAN IP, for example:

`http://192.168.2.104:8000`

Do not use `127.0.0.1` from a physical Android phone.

## Development admin
Register a normal account, log in through Swagger, then call:

`PATCH /auth/make-admin`

using the bearer token.

A driver is created with:

`POST /drivers/register`

and starts with `is_verified=false`. An admin can verify the driver through:

`PATCH /admin/drivers/{driver_id}/verify`
