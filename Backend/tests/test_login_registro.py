from .test_sistema_base import SistemaBaseTest

from usuarios.models import Usuario

class LoginRegistroTest(SistemaBaseTest):

    def test_login_correcto(self):

        response = self.client.post('/api/auth/login/', {
            'username': "111222331",
            'password': "test1234"
        })

        self.assertEqual(response.status_code, 200)
        self.assertIn('token', response.data)


    def test_login_credenciales_incorrectas(self):

        response = self.client.post('/api/auth/login/', {
            'username': "111222331",
            'password': "incorrecta"
        })
        self.assertEqual(response.status_code, 400)

    def test_registro_cliente_nuevo(self):
        response = self.client.post('/api/auth/register/', {
            'telefono':'333222111',
            'password':'test1234',
            'first_name' : 'Nuevo',
            'last_name' : 'Cliente',
            'email' : 'nuevo@test.com'
        })

        self.assertEqual(response.status_code, 201)
        self.assertTrue( Usuario.objects.filter(telefono='333222111').exists())

    def test_registro_telefono_duplicado_activo(self):
        response = self.client.post('/api/auth/register/', {
                    'telefono':'111222331',
                    'password':'test1234',
                    'first_name' : 'Otro',
                    'last_name' : 'Cliente',
                    'email' : 'otro@test.com'
                })
        
        self.assertEqual(response.status_code, 400)

    def test_registro_telefono_duplicado_inactivo(self):
        response = self.client.post('/api/auth/register/', {
            'telefono':'111222334',
            'password':'test1234',
            'first_name' : 'activo',
            'last_name' : 'Cliente',
            'email' : 'activo@test.com'
        })

        self.assertEqual(response.status_code, 201)
        usuario = Usuario.objects.get(telefono = '111222334')
        self.assertTrue(usuario.is_active)
        self.assertEqual(
            Usuario.objects.filter(telefono='111222334').count(), 1
        )

    def test_registro_siempre_cliente(self):
        response = self.client.post('/api/auth/register/', {
                    'telefono':'333222115',
                    'password':'test1234',
                    'first_name' : 'Nuevo',
                    'last_name' : 'Cliente',
                    'email' : 'nuevo@test.com',
                    'rol': 'jefe'
                })
        self.assertEqual(response.status_code, 201)
        usuario = Usuario.objects.get(telefono = '333222115')
        self.assertEqual(usuario.rol, Usuario.Roles.CLIENTE)