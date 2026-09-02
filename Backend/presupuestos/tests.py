from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from datetime import timedelta

from .services import CalculoEntregaService, PresupuestoService
from .models import Distancia, Presupuesto, Fianza, LineaPresupuesto, OpcionSeleccionada

from usuarios.models import Usuario
from proyectos.models import TipoEntrega, Proyecto, MetodoPago, EstadoProyecto
from productos.models import Producto, Caracteristica, Opcion

class CalculoEntregaTest(TestCase):
    def setUp(self):
        Distancia.objects.create(
            id=1,
            distancia_maxima=50
        )

    def test_montaje_disponible(self):
        opciones = CalculoEntregaService.calcularOpciones(
            lat=37.294,
            lon=-4.871
        )

        self.assertIn(TipoEntrega.MONTAJE, opciones)

    def test_montaje_no_disponible(self):   # coordenadas de madrid
        opciones = CalculoEntregaService.calcularOpciones(
            lat=40.444,
            lon=-3.703
        )

        self.assertNotIn(TipoEntrega.MONTAJE, opciones)

class RecalcularTest(TestCase):

    def setUp(self):

        Fianza.objects.create(
            id=1,
            porcentaje=30
        )

        self.usuario = Usuario.objects.create_user(
            telefono="111111111",
            password="12345678",
            rol=Usuario.Roles.CLIENTE
        )

        self.presupuesto = Presupuesto.objects.create(
            cliente=self.usuario
        )

        self.proyecto = Proyecto.objects.create(
            presupuesto=self.presupuesto,
            metodo_pago=MetodoPago.ONLINE,
            estado=EstadoProyecto.REVISION,
            fecha_expiracion=timezone.now() + timedelta(days=30),
            direccion_obra="Calle Mayor",
            numero="1",
            entrega=TipoEntrega.ENVIO,
        )

        self.presupuesto_sin_proyecto = Presupuesto.objects.create(
            cliente=self.usuario
        )

        self.producto = Producto.objects.create(
            nombre="Ventana",
            precio_base=Decimal("100.00"),
            activo=True
        )

        self.caracteristica = Caracteristica.objects.create(
            producto=self.producto,
            nombre="Color"
        )

        self.opcion = Opcion.objects.create(
            caracteristica=self.caracteristica,
            nombre="Blanco",
            precio_extra=Decimal("20.00"),
            activo=True
        )

        self.linea = LineaPresupuesto.objects.create(
            presupuesto=self.presupuesto,
            producto=self.producto,
            cantidad=1,
            ancho=2,
            alto=3,
            precio_base=Decimal("0"),
            precio_final=Decimal("0")
        )

        self.opcion_seleccionada = OpcionSeleccionada.objects.create(
            linea_presupuesto=self.linea,
            opcion=self.opcion,
            precio_extra=Decimal("0")
        )
    
    def test_puede_recalcular_sin_proyecto(self):
        self.assertTrue(PresupuestoService.puede_recalcular(self.presupuesto_sin_proyecto))


    def test_puede_recalcular_revision(self):
        self.assertTrue(PresupuestoService.puede_recalcular(self.presupuesto))


    def test_no_puede_recalcular(self):
        self.proyecto.estado = EstadoProyecto.ESPERANDO_MATERIALES
        self.proyecto.save()

        self.assertFalse(PresupuestoService.puede_recalcular(self.presupuesto))


    def test_recalcula_si_necesario(self):

        PresupuestoService.recalcular_si_necesario(self.presupuesto)

        self.presupuesto.refresh_from_db()
        self.linea.refresh_from_db()
        self.opcion_seleccionada.refresh_from_db()

        self.assertEqual(self.presupuesto.total, Decimal("620.00"))
        self.assertEqual(self.presupuesto.fianza, Decimal("186.00"))
        self.assertEqual(self.linea.precio_base, Decimal("600.00"))
        self.assertEqual(self.linea.precio_final, Decimal("620.00"))
        self.assertEqual(self.opcion_seleccionada.precio_extra, Decimal("20.00"))


    def test_no_recalcula_si_no_puede(self):

        self.proyecto.estado = EstadoProyecto.ESPERANDO_MATERIALES
        self.proyecto.save()

        PresupuestoService.recalcular_si_necesario(self.presupuesto)

        self.presupuesto.refresh_from_db()

        self.assertEqual(self.presupuesto.total, Decimal("0.00"))
        self.assertEqual(self.presupuesto.fianza, Decimal("0.00"))
