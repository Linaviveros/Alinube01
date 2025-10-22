#!/usr/bin/env bash
set -euo pipefail

# 1) Migraciones + estáticos (no tumbar arranque ante fallas suaves)
if [ -f manage.py ]; then
  python manage.py migrate --noinput || true
  python manage.py collectstatic --noinput || true
else
  python ali_backend/manage.py migrate --noinput || true
  python ali_backend/manage.py collectstatic --noinput || true
fi

# 2) NO usar --chdir. Exportar rutas y settings completos
export PYTHONPATH="/app:${PYTHONPATH:-}"
export DJANGO_SETTINGS_MODULE="ali_backend.ali_backend.settings"

# 3) Arrancar gunicorn apuntando al módulo WSGI completo
exec gunicorn ali_backend.ali_backend.wsgi:application \
  --bind "0.0.0.0:${PORT:-8080}" \
  --workers 3 \
  --timeout 120
