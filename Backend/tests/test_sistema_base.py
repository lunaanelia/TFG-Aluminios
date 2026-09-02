from datetime import timedelta
from decimal import Decimal

from django.utils import timezone
from django.test import TestCase

from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token

from usuarios.models import Usuario
from proyectos.models import Proyecto, EstadoProyecto
from presupuestos.models import Presupuesto, Fianza, Distancia, LineaPresupuesto, OpcionSeleccionada, EstadosPago
from productos.models import Producto, Caracteristica, Opcion
from tareas.models import Tarea, TiempoTarea,TipoTarea
from citas.models import DiasCancelacion

class SistemaBaseTest(TestCase):
    def setUp(self):
        self.client = APIClient()

        Fianza.objects.create(id=1, porcentaje=30)
        Distancia.objects.create(id=1, distancia_maxima=50)

        TiempoTarea.objects.create(
            proceso=TipoTarea.CORTAR,
            tiempo_estimado_horas=1,
        )

        TiempoTarea.objects.create(
            proceso=TipoTarea.MECANIZAR,
            tiempo_estimado_horas=1,
        )

        TiempoTarea.objects.create(
            proceso=TipoTarea.ENSAMBLAR,
            tiempo_estimado_horas=1,
        )

        TiempoTarea.objects.create(
            proceso=TipoTarea.MONTAR,
            tiempo_estimado_horas=1,
        )

        DiasCancelacion.objects.create(
            dias_cancelacion_cita = 2
        )

        # Usuarios
        self.cliente = Usuario.objects.create_user(
            telefono='111222331',
            password='test1234',
            rol=Usuario.Roles.CLIENTE,
            first_name='Cliente',
            last_name='Test',
            email='cliente@test.com'
        )

        self.jefe = Usuario.objects.create_user(
            telefono='111222332',
            password='test1234',
            rol=Usuario.Roles.JEFE,
            first_name='Jefe',
            last_name='Test',
            email='jefe@test.com',
            horario=[
                {
                    'dia': 'Lunes',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Martes', 
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Miercoles',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Jueves',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Viernes',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
            ]
        )

        self.trabajador = Usuario.objects.create_user(
            telefono='111222333',
            password='test1234',
            rol=Usuario.Roles.TRABAJADOR,
            first_name='Trabajador',
            last_name='Test',
            email='trabajador@test.com',
            horario=[
                {
                    'dia': 'Lunes',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Martes', 
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Miercoles',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Jueves',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
                {
                    'dia': 'Viernes',
                    'turnos': [{'inicio': '08:00', 'fin': '17:00'}]
                },
            ]
        )

        self.inactivo = Usuario.objects.create_user(
            telefono='111222334',
            password='test1234',
            rol=Usuario.Roles.CLIENTE,
            first_name='inactivo',
            last_name='Test',
            email='inactivo@test.com',
            is_active = False
        )

        # Producto
        self.producto = Producto.objects.create(
            nombre='Ventana Test',
            precio_base=Decimal('100.00'),
            activo=True
        )

        self.caracteristica = Caracteristica.objects.create(
            producto=self.producto,
            nombre='Color'
        )

        self.opcion = Opcion.objects.create(
            caracteristica=self.caracteristica,
            nombre='Blanco',
            precio_extra=Decimal('0.00'),
            activo=True
        )

    def _login(self, telefono, password):
       
        response = self.client.post('/api/auth/login/', {
            'username': telefono,
            'password': password
        })

        token = response.data['token']

        self.client.credentials(
            HTTP_AUTHORIZATION=f'Token {token}'
        )

        return token

    def _crear_presupuesto(self):
        return self.client.post('/api/presupuestos', {
            'lineas': [
                {
                    'producto': self.producto.id,
                    'cantidad': 1,
                    'ancho': 2.0,
                    'alto': 3.0,
                    'opciones': [self.opcion.id]
                }
            ]
        }, format='json')


    def _crear_proyecto(self, usuario, estado=EstadoProyecto.PENDIENTE_PAGO):
    
            presupuesto = Presupuesto.objects.create(
                cliente=usuario,
                fianza=10,
                total=30,
                estado_pagado=EstadosPago.SIN_PAGAR
            )
    
            linea = LineaPresupuesto.objects.create(
                presupuesto=presupuesto,
                producto=self.producto,
                cantidad=1,
                ancho=2,
                alto=2,
                precio_base=100,
                precio_final=100,
            )
    
            OpcionSeleccionada.objects.create(
                linea_presupuesto=linea,
                opcion=self.opcion,
                precio_extra=0,
            )
    
            return Proyecto.objects.create(
                presupuesto=presupuesto,
                metodo_pago='taller',
                estado=estado,
                fecha_expiracion=timezone.now() + timedelta(days=15),
                direccion_obra='Calle Test 1',
                numero='1',
                entrega='Recogida',
                fecha_limite_pago = timezone.now()+ timedelta(days=15)
            )
    