from .test_sistema_base import SistemaBaseTest
from presupuestos.models import Presupuesto
from proyectos.models import Proyecto, EstadoProyecto

class PresupuestoTest(SistemaBaseTest):
    def test_cliente_puede_crear_presupuesto(self):
        self._login('111222331', 'test1234')
        response = self._crear_presupuesto()

        self.assertEqual(response.status_code, 201)
        self.assertEqual(Presupuesto.objects.count(), 1)

    def test_usuario_no_auth_no_presupuesto(self):
        response = self.client.post('/api/presupuestos/',{
            'lineas':[
                {
                    'producto':self.producto.id,
                    'cantidad':1,
                    'ancho':2.0,
                    'alto':3.0,
                    'opciones': [self.opcion.id]
                }
            ]
        }, format='json')

        self.assertEqual(response.status_code, 404)

   
    def test_cliente_no_puede_ver_presupuesto_de_otros(self):

        self._login('111222331', 'test1234')
        self._crear_presupuesto()

        self._login('111222333', 'test1234')

        response = self.client.get('/api/presupuestos')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 0)