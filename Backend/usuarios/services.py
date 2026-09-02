from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode # Añadido decode
from django.utils.encoding import force_bytes
from django.core.mail import send_mail

from enum import Enum

from .models import Usuario

from tareas.models import Tarea, Estado
from proyectos.models import Proyecto, EstadoProyecto
from presupuestos.models import Presupuesto


class ResultadoDesactivacion(Enum):
    DESACTIVADO = "desactivado"
    DEGRADADO = "degradado"

class NotificacionUsuarioService:

    @staticmethod
    def reenviar_invitacion(user:Usuario) -> None:
        
        print("CORREO MANDADOOOO")

        # gereneramso token de seguridad
        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))

        # creamoes le link
        link = f"http://localhost:46115/#/configurar-password/{uid}/{token}"
        
        # enviarCorreo
        asunto = "Bienvendio al equipo"
        mensaje = f"""
            Hola {user.first_name},

            Te he dado de alta en la aplicación. Para poder entrar, debes de terminar de configurar tu contraseña.
            Para ello, haz clic en el siguiente enlace:

            {link}

            Este enlace es de un único uso.

            Este enlace expirá en 24 horas por motivos de seguridad
            """

       
        send_mail(asunto, mensaje, None, [user.email])
    
    @staticmethod
    def enviar_reset_password(user:Usuario) -> None:
        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))

        link = f"http://localhost:46115/#/configurar-password/{uid}/{token}"

        asunto = "Recuperación de contraseña"
        mensaje = f"""
            Hola {user.first_name},

            Para cambiar tu contraseña has clic en el siguiente link
            {link}

            Este enlace es de un único uso. Si usted no ha sido porfavor ignore este mensaje.

            Este enlace expirá en 24 horas por motivos de seguridad
            """
        send_mail(asunto, mensaje, None, [user.email],  fail_silently=False)


class UsuarioService:
    @staticmethod
    def registrar_cliente (validated_data : dict) -> Usuario:
        
        telefono = validated_data.get('telefono')
        
        usuario_existente = Usuario.objects.filter(telefono = telefono).first()

        if usuario_existente and usuario_existente.is_active:
           raise ValueError("Ya hay un télefono asociado a esta cuenta.")
        
        
        # Usuario desactivado, se reactiva con los nuevos datos
        if usuario_existente and not usuario_existente.is_active:
            usuario_existente.first_name = validated_data.get('first_name')
            usuario_existente.last_name = validated_data.get('last_name')
            usuario_existente.email = validated_data.get('email')

            usuario_existente.rol = Usuario.Roles.CLIENTE
            usuario_existente.is_active = True

            password = validated_data.get('password')
            usuario_existente.set_password(password)

            usuario_existente.save()

            return usuario_existente
        
        validated_data['username'] = telefono
        validated_data['rol'] = Usuario.Roles.CLIENTE

        return Usuario.objects.create_user(**validated_data)
    
    @staticmethod
    def invitar_usuario(data: dict, request) -> Usuario:
        telefono = data.get('telefono')
        usuario_existente =  Usuario.objects.filter(telefono=telefono).first()

        if usuario_existente:
            if usuario_existente.is_active:
                raise ValueError("Ya existe un usuario con ese telefono.")
            
            # Si el usuario no esta activo, actualizamos sus datos
            usuario_existente.first_name = data.get('first_name')
            usuario_existente.last_name = data.get('last_name')
            usuario_existente.email = data.get('email')
            usuario_existente.rol = data.get('rol')
            usuario_existente.horario = data.get('horario', [])
            usuario_existente.is_active = True
            usuario_existente.password_pendiente = True
            usuario_existente.set_unusable_password()
            usuario_existente.save()
            user = usuario_existente
        
        else:   
            from .serializers import UsuarioSerializer
            serializer  = UsuarioSerializer(data = data, context={'request':request})
            serializer.is_valid(raise_exception=True)
            user = serializer.save()
            user.is_active = True
            user.password_pendiente = True
            user.set_unusable_password()
            user.save()
                
        if user.is_trabajador or user.is_boss:
            from tareas.services import TareaService
            TareaService.replanificar_todo()


        return user
    
    @staticmethod
    def confirmar_password(uidb64:str, token: str, password: str) -> bool:
        try:
            uid = urlsafe_base64_decode(uidb64).decode()
            user = Usuario.objects.get(pk=uid)
        except (TypeError, ValueError, OverflowError, Usuario.DoesNotExist):
            return False

        #Validar que el token sea correcto para ese usuario
        if user is not None and default_token_generator.check_token(user, token):
            user.set_password(password)
            user.password_pendiente = False
            user.save()
            return True
        else:
            return False
        
    @staticmethod
    def reset_password(telefono:str) -> None:
        
        try:
            user = Usuario.objects.get(telefono=telefono)
        except Usuario.DoesNotExist:
            raise ValueError("Usuario no encontrado.")
        
        NotificacionUsuarioService.enviar_reset_password(user)

    @staticmethod
    def actualizar_usuario(usuario : Usuario, horario_viejo, rol_viejo) -> None:
        change_horario = (horario_viejo != usuario.horario)
        change_rol = (rol_viejo!=usuario.rol) and (rol_viejo == Usuario.Roles.TRABAJADOR or usuario.rol == Usuario.Roles.TRABAJADOR)
        
        deja_produccion = (
            rol_viejo in [Usuario.Roles.TRABAJADOR, Usuario.Roles.JEFE] and
            usuario.rol not in [Usuario.Roles.TRABAJADOR, Usuario.Roles.JEFE]
        )

        if deja_produccion:
            Tarea.objects.filter(
                trabajador=usuario,
                estado__in=[
                    Estado.PENDIENTE,
                    Estado.EN_PROCESO,
                ]
            ).update(
                trabajador=None
            )  
        
        if change_horario or change_rol:
            from tareas.services import TareaService
            TareaService.replanificar_todo()

    @staticmethod
    def desactivar_cuenta_cliente(usuario : Usuario) -> None:
        proyectos_activos = Proyecto.objects.filter(
                presupuesto__cliente=usuario
            ).exclude(
                estado__in =[
                    EstadoProyecto.FINALIZADO,
                    EstadoProyecto.CANCELADO,
                    EstadoProyecto.EXPIRADO
                ] 
            )

        # Si tiene proyectos activos, no dejamos que elimine la cuenta
        if proyectos_activos.exists():
            raise ValueError("No puedes eleminar tu cuenta, tienes proyectos activos")

        # En el caso de que no tenga proyecos activos, marcamos sus proyectos como desactivados
        Proyecto.objects.filter(
            presupuesto__cliente=usuario
        ).update(activo=False)

        # Borramos los presupuestos que no esten asociados a ningun proyecto
        Presupuesto.objects.filter(
            cliente=usuario,
            proyecto__isnull=True
        ).delete()

        # Desactivamos usuario
        usuario.is_active = False
        usuario.save()

        
    @staticmethod
    def descativar_trabajador(usuario : Usuario) -> ResultadoDesactivacion:
        tiene_presupuestos_sin_confirmar = Presupuesto.objects.filter(
            cliente = usuario,
            proyecto__isnull=True
        ).exists()

        tiene_proyectos_activos = Proyecto.objects.filter(
            presupuesto__cliente = usuario,
            activo = True
        ).exists()

        from tareas.services import TareaService

        if tiene_presupuestos_sin_confirmar or tiene_proyectos_activos:
            
            
            usuario.rol = Usuario.Roles.CLIENTE
            usuario.save()

            Tarea.objects.filter(
                trabajador=usuario,
                estado__in=[
                    Estado.PENDIENTE,
                    Estado.EN_PROCESO,
                ]
            ).update(
                trabajador=None
            )
                        
            TareaService.replanificar_todo()
            
            return ResultadoDesactivacion.DEGRADADO
        

        usuario.rol = Usuario.Roles.CLIENTE
        usuario.is_active = False
        usuario.save()

        Tarea.objects.filter(
            trabajador=usuario,
            estado__in=[
                Estado.PENDIENTE,
                Estado.EN_PROCESO,
            ]
        ).update(
            trabajador=None
        )
        
        TareaService.replanificar_todo() # Replanificamos todo

        return ResultadoDesactivacion.DESACTIVADO
        