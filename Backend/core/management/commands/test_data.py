from django.core.management.base import BaseCommand
from decimal import Decimal
from django.utils import timezone
from datetime import timedelta
from usuarios.models import Usuario
from productos.models import Producto, Caracteristica, Opcion
from presupuestos.models import Presupuesto, OpcionSeleccionada, LineaPresupuesto, EstadosPago
from proyectos.models import Proyecto, EstadoProyecto
from tareas.models import Tarea, TipoTarea, Estado

class Command(BaseCommand):
    help = 'Crea los datos necesarios para los test de sistema'

    def handle(self, *args, **options):
        self.jefe = self._crear_usuario('111222331', Usuario.Roles.JEFE, 'jefe', 'jefe@test.com')
        self.cliente = self._crear_usuario('111222332', Usuario.Roles.CLIENTE, 'cliente', 'cliente@test.com')
        
        self.stdout.write(self.style.SUCCESS(
            'Usuarios para los test creados correctamente'
        ))

        self.producto, _= Producto.objects.get_or_create(
                nombre='Ventana Test',
                precio_base=Decimal('100.00'),
                activo=True
            )

        
        self.caracteristica, _ = Caracteristica.objects.get_or_create(
            producto=self.producto,
            nombre='Color'
        )

        self.opcion, _ = Opcion.objects.get_or_create(
            caracteristica=self.caracteristica,
            nombre='Blanco',
            precio_extra=Decimal('0.00'),
            activo=True
        )

        self.stdout.write(self.style.SUCCESS(
            ' producto para el test creado correctamente'
        ))

        self.presupuesto = Presupuesto.objects.create(
            cliente=self.cliente,
            fianza=10,
            total=30,
            estado_pagado=EstadosPago.PAGADO
        )

        self.linea = LineaPresupuesto.objects.create(
            presupuesto=self.presupuesto,
            producto=self.producto,
            cantidad=1,
            ancho=2,
            alto=2,
            precio_base=100,
            precio_final=100,
        )
            
        OpcionSeleccionada.objects.create(
            linea_presupuesto=self.linea,
            opcion=self.opcion,
            precio_extra=0,
        )

        self.presupuesto2 = Presupuesto.objects.create(
            cliente=self.cliente,
            fianza=10,
            total=30,
            estado_pagado=EstadosPago.PAGADO
        )

        self.linea2 = LineaPresupuesto.objects.create(
            presupuesto=self.presupuesto2,
            producto=self.producto,
            cantidad=1,
            ancho=2,
            alto=2,
            precio_base=100,
            precio_final=100,
        )
            
        OpcionSeleccionada.objects.create(
            linea_presupuesto=self.linea2,
            opcion=self.opcion,
            precio_extra=0,
        )
            
        self.proyecto = Proyecto.objects.create(
            presupuesto=self.presupuesto,
            metodo_pago='taller',
            estado=EstadoProyecto.REVISION,
            fecha_expiracion=timezone.now() + timedelta(days=15),
            direccion_obra='Calle Test 1',
            numero='1',
            entrega='Recogida',
            fecha_limite_pago = timezone.now()+ timedelta(days=15)
        )

        self.stdout.write(self.style.SUCCESS(
            ' proyecto para el test creado correctamente'
        ))

        tarea_1 = Tarea.objects.create(
            proyecto=self.proyecto,
            linea_presupuesto=self.linea,
            tipo=TipoTarea.MONTAJE,
            estado=Estado.PENDIENTE,
            tiempo_estimado_horas=3.0,
            orden=1,
            bloqueada=False,
        )
        tarea_1.trabajadores_montaje.add(self.jefe)

        tarea_2 = Tarea.objects.create(
            proyecto=self.proyecto,
            linea_presupuesto=self.linea,
            tipo=TipoTarea.MONTAJE,
            estado=Estado.PENDIENTE,
            tiempo_estimado_horas=3.0,
            orden=2,
            depende_de=tarea_1,
            bloqueada=True,
        )
        tarea_2.trabajadores_montaje.add(self.jefe)

        self.stdout.write(self.style.SUCCESS(
            ' tareas para el test creado correctamente'
        ))


        

        
    def _crear_usuario(self, tlfn, rol, nombre, gmail):

        usuario, creado = Usuario.objects.get_or_create(
            telefono=tlfn,
            rol= rol,
            first_name= nombre,
            last_name = "test",
            email=gmail,
            is_active = True,
            username=tlfn
        )

        usuario.set_password('test1234')
        usuario.save()

        return usuario