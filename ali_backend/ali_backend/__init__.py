from __future__ import absolute_import, unicode_literals

# Evita que el sitio caiga si Celery no está disponible
try:
    from .celery import app as celery_app  # noqa: F401
except Exception:
    celery_app = None

__all__ = ('celery_app',)
