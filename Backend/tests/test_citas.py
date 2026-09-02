from .test_sistema_base import SistemaBaseTest
from django.utils import timezone
from datetime import timedelta

from usuarios.models import Usuario
from citas.models import Cita, EstadoCita
from proyectos.models import EstadoProyecto

class CitaTest(SistemaBaseTest):

    def _crear_cita(self, fecha, inicio, fin):
        return self.client.post('/api/citas',{
            "fecha":fecha,
            "hora_inicio":inicio,
            "hora_fin":fin
        }, format="json")

    
    def test_jefe_crea_cita(self):

        # Login como jefe
        self._login('111222332', 'test1234')

        # fecha
        fecha = (timezone.now() + timedelta(days=15)).date().isoformat()
        response = self.client.post('/api/citas',{
            "fecha":fecha,
            "hora_inicio":"10:00",
            "hora_fin":"10:30"
        }, format="json")

        self.assertEqual(response.status_code, 201)
        cita = Cita.objects.get(id=response.data['id'])
        self.assertEqual(cita.estado, EstadoCita.DISPONIBLE)

    def test_reserva_cita(self):
        # Login como jefe
        self._login('111222332', 'test1234')

        # fecha
        fecha = (timezone.now() + timedelta(days=15)).date().isoformat()

        response = self._crear_cita(fecha, "12:00:00", "12:30:00")

        cita = Cita.objects.get(id=response.data['id'])

        # Login cliente para reserva de cita
        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(usuario=self.cliente, estado=EstadoProyecto.PENDIENTE_CITA)

        response = self.client.post(f'/api/citas/{cita.id}/reservar', {
            'proyecto_id':proyecto.id
        }, format='json')
        
        proyecto.refresh_from_db()  
        cita.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(cita.estado, EstadoCita.RESERVADA)
        self.assertEqual(proyecto.estado, EstadoProyecto.REVISION)

    def test_anulacion_cita_correcta(self):
        self._login('111222332', 'test1234')
        fecha = (timezone.now() + timedelta(days=15)).date().isoformat()
        response = self._crear_cita(fecha, "12:00:00", "12:30:00")
        cita = Cita.objects.get(id=response.data['id'])

        # Login cliente para reserva de cita y anular cita
        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(usuario=self.cliente, estado=EstadoProyecto.PENDIENTE_CITA)

        response = self.client.post(f'/api/citas/{cita.id}/reservar', {
            'proyecto_id':proyecto.id
        }, format='json')
        
        proyecto.refresh_from_db()  
        cita.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(cita.estado, EstadoCita.RESERVADA)
        self.assertEqual(proyecto.estado, EstadoProyecto.REVISION)
        
        response = self.client.post(f'/api/citas/{cita.id}/cancelar')

        proyecto.refresh_from_db()  
        cita.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(cita.estado, EstadoCita.DISPONIBLE)
        self.assertEqual(proyecto.estado, EstadoProyecto.PENDIENTE_CITA)
                

    def test_anulacion_cita_incorrecta(self):
        self._login('111222332', 'test1234')
        fecha = (timezone.now() + timedelta(days=1)).date().isoformat()
        response = self._crear_cita(fecha, "12:00:00", "12:30:00")
        cita = Cita.objects.get(id=response.data['id'])

        # Login cliente para reserva de cita y anular cita
        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(usuario=self.cliente, estado=EstadoProyecto.PENDIENTE_CITA)

        response = self.client.post(f'/api/citas/{cita.id}/reservar', {
            'proyecto_id':proyecto.id
        }, format='json')
        
        proyecto.refresh_from_db()  
        cita.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(cita.estado, EstadoCita.RESERVADA)
        self.assertEqual(proyecto.estado, EstadoProyecto.REVISION)
        
        response = self.client.post(f'/api/citas/{cita.id}/cancelar')

        self.assertEqual(response.status_code, 400)         

    def test_borrado_cita_disponible(self):
        self._login('111222332', 'test1234')
        fecha = (timezone.now() + timedelta(days=15)).date().isoformat()
        response = self._crear_cita(fecha, "12:00:00", "12:30:00")
        cita = Cita.objects.get(id=response.data['id'])

        response = self.client.delete(f'/api/citas/{cita.id}')
        self.assertEqual(response.status_code, 204)
        self.assertFalse(Cita.objects.filter(id=cita.id).exists())        

    
    def test_borrado_cita_reservada(self):
        self._login('111222332', 'test1234')
        fecha = (timezone.now() + timedelta(days=15)).date().isoformat()
        response = self._crear_cita(fecha, "12:00:00", "12:30:00")
        cita = Cita.objects.get(id=response.data['id'])


        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(self.cliente, EstadoProyecto.PENDIENTE_CITA)
        self.client.post(f'/api/citas/{cita.id}/reservar',{
            "proyecto_id":proyecto.id
        }, format="json")

        self._login('111222332', 'test1234')
        response = self.client.delete(f'/api/citas/{cita.id}')
        self.assertEqual(response.status_code, 400)
        self.assertTrue(Cita.objects.filter(id=cita.id).exists())        

    def test_no_reservar_cita_reservada(self):
        self._login('111222332', 'test1234')
        fecha = (timezone.now() + timedelta(days=15)).date().isoformat()
        response = self._crear_cita(fecha, "12:00:00", "12:30:00")
        cita = Cita.objects.get(id=response.data['id'])

        # Login cliente para reserva de cita
        self._login('111222331', 'test1234')
        proyecto = self._crear_proyecto(usuario=self.cliente, estado=EstadoProyecto.PENDIENTE_CITA)

        response = self.client.post(f'/api/citas/{cita.id}/reservar', {
            'proyecto_id':proyecto.id
        }, format='json')
        
        proyecto.refresh_from_db()  
        cita.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(cita.estado, EstadoCita.RESERVADA)
        self.assertEqual(proyecto.estado, EstadoProyecto.REVISION)

        # login comootro cliente y reserva
        self._login('111222333', 'test1234')
        proyecto_t = self._crear_proyecto(usuario=self.trabajador, estado=EstadoProyecto.PENDIENTE_CITA)

        response = self.client.post(f'/api/citas/{cita.id}/reservar', {
            'proyecto_id':proyecto_t.id
        }, format='json')

        self.assertEqual(response.status_code, 400)

    def test_no_dos_citas_mismo_rango(self):
        self._login('111222332', 'test1234')
        fecha = (timezone.now() + timedelta(days=15)).date().isoformat()
        self._crear_cita(fecha, "12:00:00", "12:30:00")
    

        response = self._crear_cita(fecha, "12:00:00", "12:30:00")
        self.assertEqual(response.status_code, 400)
                