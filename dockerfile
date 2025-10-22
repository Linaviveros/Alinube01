# =========================
# STAGE 1: Build del FRONT (Flutter Web)
# =========================
FROM ghcr.io/cirruslabs/flutter:stable AS front-builder
WORKDIR /app/front
COPY Ali_Front/ali_fronted/ ./
RUN flutter config --enable-web \
 && flutter pub get \
 && flutter build web --release

# =========================
# STAGE 2: Backend Django + Gunicorn
# =========================
FROM python:3.12-slim AS backend

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=ali_backend.settings \
    SECRET_KEY=dummy_for_build \
    PIP_ONLY_BINARY=:all: \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Confirmación visible en logs
RUN python -V

# Código backend
COPY ali_backend/ ./ali_backend/
COPY manage.py ./

# Requisitos (acepta requirements.txt o requeriments.txt)
COPY requirements.txt requeriments.txt* ./
RUN bash -lc ' \
  if [ -f requirements.txt ]; then \
      echo "[pip] usando requirements.txt"; \
      pip install --no-cache-dir --prefer-binary -r requirements.txt; \
  elif [ -f requeriments.txt ]; then \
      echo "[pip] usando requeriments.txt"; \
      pip install --no-cache-dir --prefer-binary -r requeriments.txt; \
  else \
      echo "No hay requirements.txt / requeriments.txt" && exit 1; \
  fi'

# Front compilado → estáticos del backend
COPY --from=front-builder /app/front/build/web/ ./ali_backend/static/app/

# collectstatic (WhiteNoise)
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD bash -lc "\
  python ali_backend/manage.py migrate --noinput && \
  python ali_backend/manage.py collectstatic --noinput && \
  gunicorn ali_backend.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 90 \
"
