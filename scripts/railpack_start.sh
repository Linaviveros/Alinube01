#!/usr/bin/env bash
set -euo pipefail

# ---- rutas según tu repo ----
APP_DIR="/app/ali_backend"        # donde está manage.py
PKG="ali_backend"                  # nombre del paquete (inner)

# Asegura import path y settings correctos
export PYTHONPATH="/app:${APP_DIR}:${PYTHONPATH:-}"
export DJANGO_SETTINGS_MODULE="${PKG}.settings"

# Migraciones + estáticos
cd "${APP_DIR}"
python manage.py migrate --noinput || true
python manage.py collectstatic --noinput || true

# (Opcional) test de imports para log claro
python - <<'PY'
import importlib
for m in ["ali_backend", "ali_backend.settings", "ali_backend.wsgi"]:
    importlib.import_module(m)
    print("OK import", m)
PY

# Arranca Gunicorn apuntando al paquete correcto
exec gunicorn "${PKG}.wsgi:application" \
  --chdir "${APP_DIR}" \
  --bind "0.0.0.0:${PORT:-8080}" \
  --workers 3 \
  --timeout 120
