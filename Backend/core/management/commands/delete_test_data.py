from django.core.management.base import BaseCommand
from usuarios.models import Usuario
from productos.models import Producto
from presupuestos.models import Presupuesto
from proyectos.models import Proyecto
from tareas.models import Tarea
from citas.models import Cita


class Command(BaseCommand):
    help = 'Elimina todos los datos creados para los test de sistema'

    def handle(self, *args, **options):
        telefonos_test = ['111222331', '111222332']

        clientes = Usuario.objects.filter(telefono__in=telefonos_test)


        proyectos_borrados, _ = Proyecto.objects.filter(
            presupuesto__cliente__in=clientes
        ).delete()

        presupuestos_borrados, _ = Presupuesto.objects.filter(
            cliente__in=clientes
        ).delete()
        
        Producto.objects.filter(nombre='Ventana Test').delete()

        usuarios_borrados, _ = clientes.delete()

        self.stdout.write(self.style.SUCCESS(
            f'Limpieza completada: '
            f'{proyectos_borrados} proyecto, '
            f'{presupuestos_borrados} presupuesto, '
            f'{usuarios_borrados} usuario(s) de test eliminadostest eliminados (citas y tareas incluidas por cascada)..'
        ))