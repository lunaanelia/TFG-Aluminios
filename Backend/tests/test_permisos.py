from .test_sistema_base import SistemaBaseTest
from usuarios.models import Usuario

class PermisosTest(SistemaBaseTest):
    def test_trabajador_no_puede_ver_todas_las_tareas(self):
        self._login('111222333', 'test1234')
        response = self.client.get('/api/tareas/todas')
        self.assertEqual(response.status_code, 403)

    def test_jefe_puede_ver_todas_las_tareas(self):
        self._login('111222332', 'test1234')
        response = self.client.get('/api/tareas/todas')
        self.assertEqual(response.status_code, 200)

    def test_cliente_no_puede_crear_usuario(self):
        self._login('111222331', 'test1234')
        response = self.client.post('/api/usuarios', {
            'telefono': '611111111',
            'password': 'test1234',
            'rol': 'trabajador',
            'first_name': 'Test',
            'last_name': 'Test',
            'email': 'test@test.com'
        })
        self.assertEqual(response.status_code, 403)

    def test_jefe_puede_crear_usuario(self):
        self._login('111222332', 'test1234')

        response = self.client.post('/api/usuarios', {
            'telefono': '611111111',
            'password': 'test1234',
            'rol': 'trabajador',
            'first_name': 'Test',
            'last_name': 'Test',
            'email': 'test@test.com'
        })
        self.assertEqual(response.status_code, 201)

    def test_usuario_no_borrar_otro_usuario(self):
        self._login('111222331', 'test1234')
        response = self.client.delete(f'/api/usuarios/{self.jefe.id}')
        self.assertEqual(response.status_code, 404)

    def test_jefe_no_borra_cliente(self):
        self._login('111222332', 'test1234')
        response = self.client.delete(f'/api/usuarios/{self.cliente.id}')
        self.assertEqual(response.status_code, 403)

    def test_jefe_borrar_trabajador(self):
        self._login('111222332', 'test1234')
        response = self.client.delete(f'/api/usuarios/{self.trabajador.id}')
        self.assertEqual(response.status_code, 200)

    def test_usuario_no_autenticado_no_puede_acceder_a_proyectos(self):
        response = self.client.get('/api/proyectos')
        self.assertEqual(response.status_code, 401)

    def test_user_no_ve_otros(self):
        self._login('111222331', 'test1234')
        response = self.client.get(f'/api/usuarios')
        self.assertEqual(len(response.data),1)

    def test_jefe_ve_otros_user(self):
        self._login('111222332', 'test1234')
        response = self.client.get(f'/api/usuarios')
        self.assertTrue(len(response.data)>=1)

    def test_trabjador_no_otros_usuairos_o(self):
            self._login('111222333', 'test1234')
            
            response = self.client.get('/api/usuarios')
    
            self.assertEqual(response.status_code, 403)

    def test_cliente_no_puede_modificar_rol_propio(self):
        self._login('111222331', 'test1234')
        response = self.client.patch(
            f'/api/usuarios/{self.cliente.id}/',
            {'rol': 'jefe'},
            format='json'
        )
        
        self.cliente.refresh_from_db()
        self.assertNotEqual(self.cliente.rol, Usuario.Roles.JEFE)

    def test_jefe_puede_modificar_rol_de_usuario(self):
        self._login('111222332', 'test1234')
        response = self.client.patch(
            f'/api/usuarios/{self.trabajador.id}',
            {'rol': 'administrativo'},
            format='json'
        )
        self.trabajador.refresh_from_db()
        self.assertEqual(self.trabajador.rol, Usuario.Roles.ADMINISTRATIVO)