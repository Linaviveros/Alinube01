from celery import shared_task
from django.core.mail import send_mail
from django.contrib.auth import get_user_model

User = get_user_model()

@shared_task
def enviar_recordatorios_estudiantes():
    estudiantes = User.objects.filter(is_staff=False, progreso__in=["Noiniciado", "Enprogreso"])
    for estudiante in estudiantes:
        send_mail(
            subject="⏳ Recordatorio: test vocacional incompleto",
            message=f"Hola {estudiante.first_name}, recuerda completar tu test vocacional en la plataforma ALI.",
            from_email="ali.plataforma@gmail.com",
            recipient_list=[estudiante.email],
            fail_silently=False,
        )

@shared_task
def notificar_admins_estudiantes_inactivos():
    estudiantes_inactivos = User.objects.filter(is_staff=False, progreso="Noiniciado")
    if estudiantes_inactivos.exists():
        lista_nombres = ", ".join([f"{e.first_name} {e.last_name}" for e in estudiantes_inactivos])
        admins = User.objects.filter(is_staff=True)
        for admin in admins:
            send_mail(
                subject="🚨 Alerta: estudiantes sin iniciar test",
                message=f"Administrador, los siguientes estudiantes no han iniciado su test: {lista_nombres}",
                from_email="ali.plataforma@gmail.com",
                recipient_list=[admin.email],
                fail_silently=False,
            )
