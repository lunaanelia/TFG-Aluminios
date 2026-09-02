from .test_sistema_base import SistemaBaseTest
from presupuestos.models import Presupuesto, EstadosPago, OpcionSeleccionada, LineaPresupuesto
from proyectos.models import Proyecto, EstadoProyecto
from django.utils import timezone
from datetime import timedelta
from citas.models import Cita, EstadoCita
from tareas.models import Tarea

class ProyectoTest(SistemaBaseTest):
    # Creación de proyectos
    def test_flujo_crear_proyecto(self):
        self._login('111222331', 'test1234')

        # Crea presupuesto
        response = self._crear_presupuesto()
        
        p_id = response.data['id']

        # Confirmación del presupuesto creado
        response = self.client.post('/api/proyectos', {
            'presupuesto_id':p_id,
            'metodo_pago':'online',
            'entrega':'Envio',
            'direccion_obra': 'calle test',
            'numero':'1',
            'latitud': 37.3,
            'longitud': -4.8
        }, format='json')


        self.assertEqual(response.status_code, 201)
        self.assertEqual(Proyecto.objects.first().estado, EstadoProyecto.PENDIENTE_PAGO)
    
    # Cancelacion de proyectos
    def test_cliente_puede_cancelar_pendiente_pago(self):
        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(self.cliente, EstadoProyecto.PENDIENTE_PAGO)

        response = self.client.post(f'/api/proyectos/{proyecto.id}/cancelar')

        self.assertEqual(response.status_code, 200)
        proyecto.refresh_from_db()
        self.assertEqual(proyecto.estado, EstadoProyecto.CANCELADO)

    def test_cliente_puede_cancelar_pendiente_cita(self):

        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(self.cliente,EstadoProyecto.PENDIENTE_CITA)

        response = self.client.post(f'/api/proyectos/{proyecto.id}/cancelar')

        self.assertEqual(response.status_code, 200)
        proyecto.refresh_from_db()
        self.assertEqual(proyecto.estado, EstadoProyecto.CANCELADO)

    def test_no_se_puede_cancelar_en_produccion(self):
        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(self.cliente, EstadoProyecto.PRODUCCION)

        response = self.client.post(f'/api/proyectos/{proyecto.id}/cancelar/')

        self.assertEqual(response.status_code, 404)
        proyecto.refresh_from_db()
        self.assertNotEqual(proyecto.estado, EstadoProyecto.CANCELADO)

    # def test_puede_cancelar_en_revision_libera_cita(self):
       
    #     # Creamos una cita
    #     self._login('111222332', 'test1234')

    #     response=self.client.post('/api/citas',{
    #         'fecha':'2026-07-25',
    #         'hora_inicio':'12:00:00',
    #         'hora_fin':'12:30:00'
    #     }, format='json')

    #     self.assertEqual(response.status_code, 201)
    #     cita_id = response.data['id']
    #     cita = Cita.objects.get(id=cita_id)
    #     self.assertEqual(cita.estado, EstadoCita.DISPONIBLE)

    #     # Reservamos esa cita para un proyecto
    #     self._login('111222331', 'test1234')
    #     proyecto = self._crear_proyecto(self.cliente, EstadoProyecto.PENDIENTE_CITA)

    #     response = self.client.post(f'/api/citas/{cita_id}/reservar', {
    #         'proyecto_id':proyecto.id
    #     }, format='json')

    #     proyecto.refresh_from_db()  
    #     cita.refresh_from_db()

    #     self.assertEqual(response.status_code, 200)
    #     self.assertEqual(cita.estado, EstadoCita.RESERVADA)
    #     self.assertEqual(proyecto.estado, EstadoProyecto.REVISION)

    #     # Cancelamos        
    #     response = self.client.post(f'/api/proyectos/{proyecto.id}/cancelar')

    #     self.assertEqual(response.status_code, 200)

    #     proyecto.refresh_from_db()
    #     cita.refresh_from_db()
    #     self.assertEqual(proyecto.estado, EstadoProyecto.CANCELADO)
    #     self.assertEqual(cita.estado, EstadoCita.DISPONIBLE)

                
    def test_cliente_no_puede_cancelar_proyecto_de_otro(self):
        self._login('111222332', 'test1234')
        proyecto = self._crear_proyecto(self.jefe, EstadoProyecto.PRODUCCION)
        

        # Login como cliente diferente
        self._login('111222331', 'test1234')

        response = self.client.post(f'/api/proyectos/{proyecto.id}/cancelar')

        self.assertEqual(response.status_code, 403)

    def test_confirmacion_pago(self):

        # Crear proyecto pago taller
        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(self.cliente, EstadoProyecto.PENDIENTE_PAGO)
        
        #  confirmacion de pago en el taller
        self._login('111222332', 'test1234')
        response=self.client.post(f'/api/proyectos/{proyecto.id}/pagar_taller')   
        self.assertEqual(response.status_code, 200)
        proyecto.refresh_from_db()
        self.assertEqual(proyecto.estado, EstadoProyecto.PENDIENTE_CITA)         

        
    def test_creacion_tareas(self):
        self._login('111222331', 'test1234')

        proyecto = self._crear_proyecto(self.cliente, EstadoProyecto.REVISION)

        self._login('111222332', 'test1234')

        # se comfirma
        response1 = self.client.post(f'/api/proyectos/{proyecto.id}/confirmar')
        self.assertEqual(response1.status_code, 200)
        proyecto.refresh_from_db()
        self.assertEqual(proyecto.estado, EstadoProyecto.MATERIALES)

        # Se han pedido los materiales
        response2 = self.client.post(f'/api/proyectos/{proyecto.id}/materiales_pedidos')
        self.assertEqual(response2.status_code, 200)
        proyecto.refresh_from_db()
        self.assertEqual(proyecto.estado, EstadoProyecto.ESPERANDO_MATERIALES)

        # se han recibido materiales
        response3 = self.client.post(f'/api/proyectos/{proyecto.id}/materiales_recibidos')
        self.assertEqual(response3.status_code, 200)
        proyecto.refresh_from_db()
        self.assertEqual(proyecto.estado, EstadoProyecto.PRODUCCION)  

        # se compruban que se han creado tareas a sociasdas al proyecto

        self.assertTrue(Tarea.objects.filter(proyecto=proyecto).exists())
