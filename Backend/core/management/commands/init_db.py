from django.core.management.base import BaseCommand
from django.contrib.auth.hashers import make_password
from usuarios.models import Usuario
from presupuestos.models import Fianza, Distancia
from citas.models import DiasCancelacion
from tareas.models import TiempoTarea, TipoTarea


# python manage.py init_db

# borra todo
# python manage.py flush --no-input
# python manage.py migrate
# python manage.py init_db

class Command(BaseCommand):
    help = "Inicializa la base de datos con los datos necesarios"

    def handle(self, *args, **options):

        # Jefe
        if not Usuario.objects.filter(telefono="123123123").exists():
            Usuario.objects.create_user(
                telefono="123123123",
                password="superusuario",
                rol= Usuario.Roles.JEFE,
                first_name= 'Jefe',
                last_name = "Sistema",
                email="jefe@aluminios.com",
                is_staff=True,
                is_active = True,
                is_superuser = True,
                username="123123123"
            )

            self.stdout.write(
                self.style.SUCCESS('Superusuario creado correctamente')
            )
        else:
            self.stdout.write('Superusuarios ya existe')

        # Fianza
        Fianza.objects.get_or_create(
            id=1,
            defaults={'porcentaje':10.0}
        )
        self.stdout.write(self.style.SUCCESS('Fianza configurada'))

        
        # Distancia
        Distancia.objects.get_or_create(
            id=1,
            defaults={'distancia_maxima':50.0}
        )
        self.stdout.write(self.style.SUCCESS('Distanca configurada'))

        # Dias de cancelacion
        DiasCancelacion.objects.get_or_create(
            id=1,
            defaults={'dias_cancelacion_cita':2}
        )
        self.stdout.write(self.style.SUCCESS('Dias de cancelación configurada'))

        # Tiempos tareas
        tiempos = [
            (TipoTarea.CORTAR, 2.0),
            (TipoTarea.MECANIZAR, 3.0),
            (TipoTarea.MONTAR, 4.0),
            (TipoTarea.ENSAMBLAR, 5.0),
            (TipoTarea.PREPARAR_ENVIO, 1.0),
        ]

        for tipo, horas in tiempos:
            TiempoTarea.objects.get_or_create(
                proceso=tipo,
                defaults={'tiempo_estimado_horas': horas}
            )

        self.stdout.write(self.style.SUCCESS('Tiempos de tarea configurados'))
        self.stdout.write(self.style.SUCCESS('Base de datos inicializada correctamente'))