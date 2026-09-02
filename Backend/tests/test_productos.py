from .test_sistema_base import SistemaBaseTest
from presupuestos.models import Presupuesto
from proyectos.models import Proyecto, EstadoProyecto
from productos.models import Producto, Caracteristica, Opcion, Habitacion, Recomendacion

class ProductosTest(SistemaBaseTest):

    def test_crear_producto(self):
        self._login("111222332", "test1234")

        response = self.client.post('/api/productos', {
            "nombre": "Ventana",
            "descripcion": "",
            "precio_base": 120,
            "caracteristicas":[
                {
                    "nombre": "c1",
                    "opciones":[
                        {
                            "nombre":"opc-1",
                            "descripcion":"descripcion test",
                            "precio_extra":10,
                            "habitaciones_recomendadas":[]
                        }
                    ]
                }
            ]
        }, format="json")

        self.assertEqual(response.status_code, 201)

        producto = Producto.objects.get(id=response.data["id"])
        self.assertEqual(producto.nombre, "Ventana")


    def test_eliminar_producto_sin_usar(self):
        self._login("111222332", "test1234")

        response = self.client.delete(f'/api/productos/{self.producto.id}')
        self.assertEqual(response.status_code, 204)
        self.assertFalse( Producto.objects.filter(id=self.producto.id).exists())

    def test_producto_inactivo_no_listado(self):
        self._login("111222332", "test1234")

        self._crear_presupuesto()

        response = self.client.delete(f'/api/productos/{self.producto.id}')
        self.assertEqual(response.status_code, 200)
        self.producto.refresh_from_db()
        self.assertFalse(self.producto.activo)

        response = self.client.get('/api/productos')
        ids = [p["id"] for p in response.data]
        self.assertNotIn(self.producto.id, ids)

    def test_crear_producto_inactivo(self):
        
        self._login("111222332", "test1234")
        
        self._crear_presupuesto()

        response = self.client.delete(f'/api/productos/{self.producto.id}')
        self.assertEqual(response.status_code, 200)
        self.producto.refresh_from_db()

        response = self.client.post('/api/productos', {
            "nombre": self.producto.nombre,
            "descripcion": "",
            "precio_base": 120,
            "caracteristicas":[
                {
                    "nombre": "c1",
                    "opciones":[
                        {
                            "nombre":"opc-1",
                            "descripcion":"descripcion test",
                            "precio_extra":10,
                            "habitaciones_recomendadas":[]
                        }
                    ]
                }
            ]
        }, format="json")

        self.producto.refresh_from_db()
        self.assertEqual(response.status_code, 201)
        self.assertTrue(self.producto.activo)
        self.assertEqual(Producto.objects.filter(nombre=self.producto.nombre).count(), 1)
