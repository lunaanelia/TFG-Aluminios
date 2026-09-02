"""
URL configuration for aluminios project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from usuarios.views import UsuarioViewSet, get_current_user, RegistroClientView, InvitacionUsuarioView, ConfirmarPasswordView, ResetPasswordView, ReenviarInvitacionView, LogoutView
# , CreacionUsarioAdminView
from productos.views import ProductoViewSet, HabitacionViewSet #RecomendacionViewSet
from presupuestos.views import PresupuestoViewSet, DistanciaView, OpcionesEntregaView, FianzaView
from proyectos.views import ProyectoViewSet
from citas.views import CitaViewSet, DiasCancelacionView
from tareas.views import TareaViewSet, TiempoTareaViewSet
from rest_framework.authtoken import views as auth_views
from core.views import BuscarDireccionView

#router = DefaultRouter()
router = DefaultRouter(trailing_slash=False)
router.register(r'usuarios', UsuarioViewSet)
# Esto genera:
# GET /api/usuarios
# GET /api/usuarios/1
# POST /api/usuarios
# PUT /api/usuarios/1 
# DELETE /api/usuarios/1

router.register(r'productos', ProductoViewSet)

router.register(r'habitaciones', HabitacionViewSet)

router.register(r'presupuestos', PresupuestoViewSet)

router.register(r'proyectos', ProyectoViewSet)

router.register(r'citas', CitaViewSet)

router.register(r'tareas', TareaViewSet)

router.register(r'tiempo-tareas', TiempoTareaViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # API principal
    path('api/', include(router.urls)), # rutas automaticas /api/usuarios, api/usuarios/id...
    
    # Autentificación
    path('api/auth/login/', auth_views.obtain_auth_token),
    path('api/auth/confirmar-password/', ConfirmarPasswordView.as_view(), name='confirmar_password'),
    path('api/auth/reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    path('api/auth/logout/', LogoutView.as_view(), name='logout'),
    
    # Usuario actual
    path('api/usuarios/current/', get_current_user),
    
    #Registro publico
    path('api/auth/register/', RegistroClientView.as_view(), name="registro_cliente"),
    
    #gestión de nuevos usuarios
    path('api/admin/invitar-usuario/', InvitacionUsuarioView.as_view(), name='invitar_usuario'),
    path('api/admin/reenviar-invitacion/', ReenviarInvitacionView.as_view(), name='invitar_reenvio'),

    # Consulta de las direcciones
    path('api/buscar-direccion/', BuscarDireccionView.as_view()),

    # url para consutar/modificar la distancia
    path('api/distancia/', DistanciaView.as_view(), name='distancia'),

    #url para saber que que opciones tiene de entrega
    path('api/opciones-entrega/', OpcionesEntregaView.as_view(), name="opciones-entrega" ),

    # Endpoints para dias cancelacion:
    path('api/dias-cancelacion/', DiasCancelacionView.as_view(), name='dias-cancelacion'),

    path('api/fianza/', FianzaView.as_view(), name='fianza'),


]
