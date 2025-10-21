from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

# Establecer configuración de Django por defecto
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ali_backend.settings')

app = Celery('ali_backend')

# Configuración desde settings.py
app.config_from_object('django.conf:settings', namespace='CELERY')

# Descubrir tareas automáticamente
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
