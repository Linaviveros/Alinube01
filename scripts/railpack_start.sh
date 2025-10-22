#!/usr/bin/env bash
set -euo pipefail

# Migraciones + estáticos (no rompas el arranque si algo menor falla)
if [ -f manage.py ]; then
  python manage.py migrate --noinput || true
  python manage.py collectstatic --noinput || true
else
  python ali_backend/manage.py migrate --noinput || true
  python ali_backend/manage.py collectstatic --noinput || true
fi

# Localiza wsgi.py y cambia a su carpeta
WSGI_FILE="ali_backend/ali_backend/wsgi.py"
if [ ! -f "$WSGI_FILE" ]; then
  echo "ERROR: no existe $WSGI_FILE" >&2
  exit 1
fi
WSGI_DIR="ali_backend/ali_backend"
echo "Usando --chdir $WSGI_DIR (wsgi:application)"

# Asegura rutas de import por si acaso
export PYTHONPATH="/app:/app/ali_backend:${PYTHONPATH:-}"

# Arranca Gunicorn cargando wsgi.py como 'wsgi:application'
exec gunicorn wsgi:application \
  --chdir "$WSGI_DIR" \
  --bind "0.0.0.0:${PORT:-8080}" \
  --workers 3 \
  --timeout 120
