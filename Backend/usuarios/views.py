import secrets

from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

from rest_framework import viewsets, generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.authentication import TokenAuthentication
from rest_framework.exceptions import NotFound
from rest_framework.exceptions import PermissionDenied

from .models import Usuario
from .serializers import UsuarioSerializer, RegistroClienteSerializer, UsuarioListSerializer
from .permissions import EsJefe, EsPropioOEsJefe
from .services import UsuarioService, NotificacionUsuarioService, ResultadoDesactivacion

class UsuarioViewSet(viewsets.ModelViewSet):
    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer
    
    # Permisos segun la acción
    def get_permissions(self):
        if self.action in ['create']: # crear solo jefe
            return [IsAuthenticated(), EsJefe()]
        
        if self.action in ['update', 'partial_update', 'retrieve', 'destroy',]:
            return[IsAuthenticated(), EsPropioOEsJefe()]
        
        if self.action == 'list':
            return [IsAuthenticated(), EsJefe()]
        return [IsAuthenticated()]
    
    # Si el usuario no es jefe solo puede ver sus datos
    # Si el usuario es jefe puede ver todo
    def get_queryset(self):
        user = self.request.user
        if user.is_boss:
            return Usuario.objects.filter(is_active = True)
        
        return Usuario.objects.filter(id=user.id)
     
    #  vemos quien puede editar quien
    def perform_update(self, serializer):
        user_to_edit = self.get_object()
        
        if not self.request.user.is_boss and self.request.user != user_to_edit:
            raise PermissionDenied("No hay permisos para editar a otros usuarios")
        
        horario_viejo = user_to_edit.horario
        rol_viejo = user_to_edit.rol
        
        user_actualizado = serializer.save()

        UsuarioService.actualizar_usuario(user_actualizado, horario_viejo, rol_viejo)

    def get_serializer_class(self):
        if self.action == 'list':
            return UsuarioListSerializer
        
        return UsuarioSerializer
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context
    
    def destroy(self, request, *args, **kwargs):
        
        usuario = self.get_object()
        usuario_peticion = request.user

        if usuario == usuario_peticion and usuario.is_cliente:
            try:
                UsuarioService.desactivar_cuenta_cliente(usuario)
                return Response({"mensaje": "Cuenta desactivada correctamente."}, status=200)
            except ValueError as e:
                return Response({"error": str(e)}, status=400)
        
        # Caso de que el jefe desactive cuenta
        if not usuario_peticion.is_boss:
            raise PermissionDenied(
                "Permiso denegado. No esta autorizado a realizar esta operación."
            )
        
        # No eliminar al unico jefe del sistema
        if usuario.is_boss:
            
            total_jefes = Usuario.objects.filter(
                rol = Usuario.Roles.JEFE,
                is_active = True
            ).count()

            # Nos aseguramos de que minimo haya un jefe en el sistema
            if total_jefes <= 1:
                return Response(
                    {
                        "error": "Debe existir al menos un jefe activo."
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        if usuario.is_cliente:
            raise PermissionDenied(
                "Permiso denegado. No esta autorizado a realizar esta operación."
            )
        
        resultado = UsuarioService.descativar_trabajador(usuario)
        if resultado == ResultadoDesactivacion.DEGRADADO:
            return Response({"mensaje": "Cambio de rol al usuario."}, status=200)
        return Response({"mensaje": "Usuario desactivado correctamente."}, status=200)
        
            

# Usuario actual (= usuario que esta logeado)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_current_user(request):
    serializer = UsuarioSerializer(request.user)
    return Response(serializer.data)

# registro de clientes
class RegistroClientView(generics.CreateAPIView):
    queryset = Usuario.objects.all()
    serializer_class = RegistroClienteSerializer
    permission_classes = [AllowAny] # no necesta otken culaquier puede crearse un usuario


@method_decorator(csrf_exempt, name='dispatch') # Saltamos el CSRF para Flutter Web
class InvitacionUsuarioView(APIView):
   
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated, EsJefe]
    
    def post(self, request):
        print(request.authenticators)
    
        data = request.data.copy()

        if 'password' not in data or not data['password']:
            random_password = secrets.token_urlsafe(24)
            data['password'] = random_password

        try:
            user = UsuarioService.invitar_usuario(data, request)
            NotificacionUsuarioService.reenviar_invitacion(user)
            return Response({"message": "Usuario invitado con éxito"}, status=201)
        except ValueError as e:
            return Response({"error": str(e)}, status=400)

@method_decorator(csrf_exempt, name='dispatch')
class ConfirmarPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        
        uidb64 = request.data.get('uid')
        token = request.data.get('token')
        new_password = request.data.get('password')

        ok = UsuarioService.confirmar_password(uidb64, token, new_password)
        if ok:
            return Response({"message": "Contraseña configurada con éxito"}, status=200)
        return Response({"error": "El enlace es inválido o ha expirado"}, status=400)

@method_decorator(csrf_exempt, name='dispatch')
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        telefono = request.data.get('telefono')
        try:
            user = Usuario.objects.get(telefono=telefono)
            NotificacionUsuarioService.enviar_reset_password(user)
       
        except Usuario.DoesNotExist:
            return Response({"error": "Usuario no existente"}, status=200)

class ReenviarInvitacionView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated, EsJefe]
    
    def post(self, request, user_id):
        

        try :
            user = Usuario.objects.get(id=user_id)
        except Usuario.DoesNotExist:
            raise NotFound("Usuario no encontrado")
        
        # SI no esta activo se lo mandamos
        if user.is_active:
            return Response({"error": "Usuario ya activo"}, status=400)

        NotificacionUsuarioService.reenviar_invitacion(user)
        return Response({"message": "Invitación reenviada correctamente."})


class LogoutView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.user.auth_token.delete()
        return Response({"message":"Sesión cerrada correctamente"})