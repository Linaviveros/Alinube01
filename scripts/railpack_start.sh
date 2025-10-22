#!/usr/bin/env bash
set -e

if [ -f manage.py ]; then
  python manage.py migrate --noinput || true
  python manage.py collectstatic --noinput || true
else
  python ali_backend/manage.py migrate --noinput || true
  python ali_backend/manage.py collectstatic --noinput || true
fi

exec gunicorn ali_backend.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 120
