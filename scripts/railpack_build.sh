set -e

echo ">>> Instala herramientas del sistema"
apt-get update -y \
 && apt-get install -y --no-install-recommends curl ca-certificates git unzip xz-utils build-essential \
 && rm -rf /var/lib/apt/lists/*

echo ">>> Instala Flutter 3.27.1 (trae Dart 3.6.x con Color.withValues)"
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz -o /tmp/flutter.tar.xz
mkdir -p /opt
tar -xJf /tmp/flutter.tar.xz -C /opt
git config --global --add safe.directory /opt/flutter
export PATH="/opt/flutter/bin:$PATH"
/opt/flutter/bin/flutter --disable-analytics || true
/opt/flutter/bin/flutter --version
/opt/flutter/bin/flutter config --enable-web

echo ">>> Build del frontend (Flutter Web)"
cd Ali_Front/ali_fronted
# Si antes agregaste el parche de intl, puedes dejarlo; no estorba:
# sed -i 's/^\(\s*intl:\s*\)\^0\.20\..*/\1^0.19.0/' pubspec.yaml
/opt/flutter/bin/flutter pub get
/opt/flutter/bin/flutter build web --release
cd -

echo ">>> Copia build web a los estáticos del backend"
mkdir -p ali_backend/static/app
cp -R Ali_Front/ali_fronted/build/web/* ali_backend/static/app/

echo ">>> Python deps"
pip install --upgrade pip
if [ -f requirements.txt ]; then
  pip install --prefer-binary -r requirements.txt
elif [ -f requeriments.txt ]; then
  pip install --prefer-binary -r requeriments.txt
else
  echo "No se encontró requirements.txt / requeriments.txt" >&2
  exit 1
fi

echo ">>> collectstatic (WhiteNoise)"
if [ -f manage.py ]; then
  python manage.py collectstatic --noinput
else
  python ali_backend/manage.py collectstatic --noinput
fi

echo ">>> Build OK"
