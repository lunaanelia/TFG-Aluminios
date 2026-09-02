from django.test import TestCase
from django.utils import timezone
from django.core.exceptions import ValidationError

from datetime import timedelta

from .models import Proyecto, EstadoProyecto, MetodoPago, TipoEntrega
from .services import ProyectoService

from usuarios.models import Usuario
from presupuestos.models import Presupuesto

class CancelarProyectoTest(TestCase):
    def setUp(self):
        self.usuario = Usuario.objects.create_user(
            telefono = "111111111",
            password="12345678",
            rol= Usuario.Roles.CLIENTE
        )

        self.presupuesto1 = Presupuesto.objects.create(
            cliente = self.usuario
        )

        self.presupuesto2 = Presupuesto.objects.create(
            cliente = self.usuario
        )
        
        self.proyecto_cancelar = Proyecto.objects.create(
            presupuesto = self.presupuesto1,
            metodo_pago = MetodoPago.ONLINE,
            estado = EstadoProyecto.REVISION,
            fecha_expiracion=timezone.now() + timedelta(days=30),
            direccion_obra="Calle Mayor 1",
            numero="1",
            entrega=TipoEntrega.ENVIO,
        )
        
        self.proyecto_sin = Proyecto.objects.create(
            presupuesto = self.presupuesto2,
            metodo_pago = MetodoPago.ONLINE,
            estado = EstadoProyecto.ESPERANDO_MATERIALES,
            fecha_expiracion=timezone.now() + timedelta(days=30),
            direccion_obra="Calle Mayor 1",
            numero="1",
            entrega=TipoEntrega.ENVIO,
        )

    def test_se_cancela(self):
        ProyectoService.cancelar_proyecto(self.proyecto_cancelar)
        
        self.proyecto_cancelar.refresh_from_db()

        self.assertEqual(self.proyecto_cancelar.estado, EstadoProyecto.CANCELADO)


    def test_no_cancela(self):
        
        with self.assertRaises(ValidationError):
            ProyectoService.cancelar_proyecto(self.proyecto_sin)
    
