#!/usr/bin/env bash
set -euo pipefail

# Migraciones + estáticos
if [ -f manage.py ]; then
  python manage.py migrate --noinput || true
  python manage.py collectstatic --noinput || true
else
  python ali_backend/manage.py migrate --noinput || true
  python ali_backend/manage.py collectstatic --noinput || true
fi

# Asegura el import path (raíz del repo y la carpeta del proyecto)
export PYTHONPATH="/app:/app/ali_backend:${PYTHONPATH:-}"
export DJANGO_SETTINGS_MODULE="ali_backend.ali_backend.settings"

# Arranca Gunicorn SIN --chdir
exec gunicorn ali_backend.ali_backend.wsgi:application \
  --bind "0.0.0.0:${PORT:-8080}" \
  --workers 3 \
  --timeout 120
