#!/usr/bin/env bash
set -euo pipefail

# 1) Migraciones y estáticos (no fallar el arranque si algo menor truena)
if [ -f manage.py ]; then
  python manage.py migrate --noinput || true
  python manage.py collectstatic --noinput || true
else
  python ali_backend/manage.py migrate --noinput || true
  python ali_backend/manage.py collectstatic --noinput || true
fi

# 2) Detectar el módulo WSGI automáticamente
if [ -f "ali_backend/wsgi.py" ]; then
  MOD="ali_backend.wsgi"
elif [ -f "ali_backend/ali_backend/wsgi.py" ]; then
  MOD="ali_backend.ali_backend.wsgi"
else
  MOD="$(python - <<'PY'
import glob, os, sys
c=[p for p in glob.glob("**/wsgi.py", recursive=True) if "/.venv/" not in p]
if not c:
    sys.exit(2)
p=c[0].replace(os.sep,"/").removesuffix(".py").replace("/"," .").replace(" ","")
print(p)
PY
  )" || true
fi

if [ -z "${MOD:-}" ]; then
  echo "ERROR: No se encontró wsgi.py en el repo." >&2
  echo "Asegúrate de tener <paquete>/wsgi.py y __init__.py en ese paquete." >&2
  exit 1
fi

# 3) Asegurar que Python pueda importar el paquete
export PYTHONPATH="/app:/app/ali_backend:${PYTHONPATH:-}"
echo "WSGI module: ${MOD}"

# 4) Arrancar Gunicorn
exec gunicorn "${MOD}:application" --bind "0.0.0.0:${PORT:-8080}" --workers 3 --timeout 120
