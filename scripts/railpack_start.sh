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

# Directorio donde está wsgi.py
WSGI_DIR="ali_backend/ali_backend"
if [ ! -f "$WSGI_DIR/wsgi.py" ]; then
  echo "ERROR: no existe $WSGI_DIR/wsgi.py" >&2
  exit 1
fi

echo "Usando --chdir $WSGI_DIR (wsgi:application)"

# Asegura paths y sobreescribe settings para el chdir
export PYTHONPATH="/app:/app/ali_backend:${PYTHONPATH:-}"
export DJANGO_SETTINGS_MODULE="settings"

# Arranca Gunicorn
exec gunicorn wsgi:application \
  --chdir "$WSGI_DIR" \
  --bind "0.0.0.0:${PORT:-8080}" \
  --workers 3 \
  --timeout 120
