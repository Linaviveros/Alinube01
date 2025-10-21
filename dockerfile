# =========================
# STAGE 1: Build del FRONT (Flutter Web)
# =========================
FROM ghcr.io/cirruslabs/flutter:stable AS front-builder

# Directorio de trabajo para el front
WORKDIR /app/front

# Copiamos sólo los archivos del proyecto Flutter
# Ajusta la ruta si tu carpeta difiere
COPY Ali_Front/ali_fronted/ ./ 

# Habilitar soporte web y descargar deps
RUN flutter config --enable-web \
 && flutter pub get

# Compilar en modo release (web)
RUN flutter build web --release

# =========================
# STAGE 2: Backend Django + Gunicorn
# =========================
FROM python:3.12-slim AS backend

# Paquetes del sistema necesarios (psycopg, compilación ligera y estáticos)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Variables mínimas
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Directorio de la app
WORKDIR /app

# Copiamos backend completo
COPY ali_backend/ ./ali_backend/
COPY manage.py ./

# Requisitos: tu repo tiene tanto "requirements.txt" como "requeriments.txt";
# instalamos el que exista (con un fallback).
COPY requirements.txt requeriments.txt* ./
RUN bash -lc 'if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; \
              elif [ -f requeriments.txt ]; then pip install --no-cache-dir -r requeriments.txt; \
              else echo "No hay requirements.txt / requeriments.txt" && exit 1; fi'

# Copiamos el build del front DENTRO de los estáticos del backend
# para que collectstatic lo mueva a STATIC_ROOT y tu catch-all lo sirva
# (ver urls.py con staticfiles_storage.open("app/index.html")).
# Quedará en ali_backend/static/app/*
COPY --from=front-builder /app/front/build/web/ ./ali_backend/static/app/

# Recopilar estáticos (usa WhiteNoise)
# Tu settings define STATIC_ROOT=BASE_DIR/'staticfiles' y WhiteNoise habilitado,
# así que collectstatic generará /app/staticfiles/* con el manifest.
# (Si no hay .env todavía, Django pedirá SECRET_KEY; definimos una temporal)
ENV DJANGO_SETTINGS_MODULE=ali_backend.settings \
    SECRET_KEY=dummy_for_build
RUN python manage.py collectstatic --noinput

# Exponemos puerto
EXPOSE 8000

# Comando de arranque: gunicorn WSGI
# (tu proyecto expone WSGI en ali_backend.wsgi.application)
CMD ["bash", "-lc", "gunicorn ali_backend.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 90"]
