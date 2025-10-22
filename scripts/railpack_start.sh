#!/usr/bin/env bash
set -euo pipefail

# Migraciones + estáticos
python ali_backend/manage.py migrate --noinput || true
python ali_backend/manage.py collectstatic --noinput || true

# Arranca gunicorn desde la carpeta que contiene wsgi.py
# (ali_backend/ali_backend) y carga wsgi:application
exec gunicorn wsgi:application \
  --chdir ali_backend/ali_backend \
  --bind "0.0.0.0:${PORT:-8080}" \
  --workers 3 \
  --timeout 120
