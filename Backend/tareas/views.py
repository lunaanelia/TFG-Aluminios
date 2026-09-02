from django.utils import timezone
from django.db import transaction
from django.db.models import Q

from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.exceptions import MethodNotAllowed
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied


from .models import Tarea, Estado, TipoTarea, TiempoTarea
from .serializers import TareaSerializer, TareaMontajeSerializer, TiempoTareaSerializer
from .services import TareaService

from core.permission import EsJefeOTrabajador, EsJefe
from presupuestos.serializers import PresupuestoReadSerializer
from proyectos.serializers import ProyectoSerializer


class TareaViewSet(viewsets.ReadOnlyModelViewSet):

    serializer_class = TareaSerializer
    permission_classes = [IsAuthenticated]

    queryset = Tarea.objects.select_related(
        'proyecto',
        'linea_presupuesto',
        'trabajador'
    )

    def get_queryset(self):
        user = self.request.user

        return Tarea.objects.filter(
            # trabajador=user
            Q(trabajador=user) |
            Q(trabajadores_montaje=user)
            ).exclude(
                estado__in = [Estado.TERMINADA, Estado.CANCELADA]

            ).order_by(
                'fecha_inicio_estimada'
            ).select_related(
                'proyecto',
                'linea_presupuesto',
                'trabajador'
            )

    def create(self, request, *args, **kwargs):
        raise MethodNotAllowed("POST")
    
    def update(self, request, *args, **kwargs):
        raise MethodNotAllowed("PUT")


    def partial_update(self, request, *args, **kwargs):
        raise MethodNotAllowed("PATCH")

    def destroy(self, request, *args, **kwargs):
        if not request.user.is_boss:
            raise PermissionDenied("Solo los jefes pueden eliminar tareas.")
        
        tarea = self.get_object()

        try:

            TareaService.eliminar_montaje(tarea=tarea)
            return Response({"mensaje": "Montaje eliminado."}, status=status.HTTP_200_OK)
            
        except Tarea.DoesNotExist:
            return Response({"error": "No existe."}, status=status.HTTP_404_NOT_FOUND)   

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        

    @action(detail=True, methods=['post'])
    def iniciar(self, request, pk=None):
        tarea = self.get_object()
        
        if not EsJefeOTrabajador:
            raise PermissionDenied("No tienes permisos para realizar esta acción")
        
        if tarea.tipo == TipoTarea.MONTAJE:
            if request.user not in tarea.trabajadores_montaje.all():
                raise PermissionDenied(
                    "No perteneces a este montaje"
                )
        else:
            if tarea.trabajador and tarea.trabajador != request.user:
                raise PermissionDenied("No puedes iniciar un tarea que no es tuya")
            
        if tarea.bloqueada:
            return Response(
                {
                    "detail": "Esta tarea esta bloqueada"
                },
                status=status.HTTP_400_BAD_REQUEST 
            )
        
        if tarea.estado != Estado.PENDIENTE:
            return Response(
                {
                    "detail": "Esta tarea ya ha sido iniciada"
                },
                status=status.HTTP_400_BAD_REQUEST 
            )
        
        
        tarea.estado = Estado.EN_PROCESO
        tarea.fecha_inicio = timezone.now()

        tarea.save()
        
        return Response(
            {
                "detail": "Estado de la tarea actualizado correctamente",
                "estado": tarea.estado
            },
            status=status.HTTP_200_OK
        )


    @action(detail=True, methods=['post'])
    def terminar(self, request, pk=None):
        tarea = self.get_object()

        if not EsJefeOTrabajador:
            raise PermissionDenied("No tienes permisos para realizar esta acción")
        
        if tarea.tipo == TipoTarea.MONTAJE:
            if request.user not in tarea.trabajadores_montaje.all():
                raise PermissionDenied(
                    "No perteneces a este montaje"
                )
        else:
            if tarea.trabajador != request.user:
                raise PermissionDenied("No puedes iniciar un tarea que no es tuya")
            

        if tarea.estado != Estado.EN_PROCESO:
            return Response(
                {
                    "detail": "Este tarea no esta iniciada"
                },
                status=status.HTTP_400_BAD_REQUEST 
            )

        try:
            TareaService.terminar_tarea(tarea=tarea)
            return Response(
                {
                    "detail": "Estado de la tarea actualizado correctamente",
                    "estado": tarea.estado
                },
                status=status.HTTP_200_OK
            )
        except ValueError as e:
            return Response({"error": str(e)}, status=400)
    


    @action(detail=False, methods=['get'])
    def todas(self, request):
        user = request.user

        if not user.is_boss:
            return Response(
                {"detail": "No tienes permisos para esta operacion"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        tareas = Tarea.objects.exclude(
            estado = Estado.CANCELADA
        ).select_related(
            'proyecto',
            'linea_presupuesto',
            'trabajador'
        ).order_by(
            'fecha_inicio_estimada',
        )

        serializer = self.get_serializer(tareas, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def crear_montaje(self, request):
        
        print("USUARIO RECIBIDO EN LA API:", request.user)

        if not request.user or request.user.is_anonymous:
            return Response(
                {"error": "No estás autenticado o el token de Flutter no ha llegado."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not request.user.is_boss:
            raise PermissionDenied(
                "Solo los jefes pueden crear montajes"
            )
        
        serializer = TareaMontajeSerializer(data=request.data, context={'request': request})

        serializer.is_valid(raise_exception=True)
      
        try:
            with transaction.atomic():

                datos = serializer.validated_data
                trabajadores = datos.pop('trabajadores_montaje')
        
                nueva_tarea = TareaService.crear_montaje(
                    proyecto=datos['proyecto'],
                    trabajadores=trabajadores,
                    fecha_inicio_estimada=datos['fecha_inicio_estimada'],
                    fecha_fin_estimada=datos['fecha_fin_estimada'],
                    tiempo_estimado_horas=datos['tiempo_estimado_horas']
                )

                response_serializer = TareaSerializer(nueva_tarea, context={'request': request})

                return Response(
                    response_serializer.data,
                    status=status.HTTP_201_CREATED
                )


        except Exception as e:
            return Response(
                {
                    "error": str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


    @action(detail=True, methods=['put'])
    def modificar_montaje(self, request, pk=None):
        
        if request.user.rol != 'jefe':
            raise PermissionDenied(
                "Solo los jefes pueden crear montajes"
            )
        
        tarea = self.get_object()
        
        serializer = TareaMontajeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        datos = serializer.validated_data
                
        try:
            trabajadores = datos.pop('trabajadores_montaje')
            tarea = TareaService.modificar_montaje(
                tarea=tarea,
                trabajadores=trabajadores,
                fecha_inicio_estimada=datos['fecha_inicio_estimada'],
                fecha_fin_estimada=datos['fecha_fin_estimada'],
                tiempo_estimado_horas=datos['tiempo_estimado_horas']
            )

            return Response(
                    TareaSerializer(tarea, context={'request': request}).data,
                    status=status.HTTP_200_OK
                )

        except Exception as e:
            return Response(
                {
                    "error": str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
    @action(detail=True, methods=['get'])
    def datos_envio(self, request, pk=None):
        tarea = self.get_object()

        if tarea.tipo != TipoTarea.PREPARAR_ENVIO:
            return Response(
                {"error": "Esta tarea no es de envío"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        es_trabajador_asignado = tarea.trabajador == request.user

        if not es_trabajador_asignado:
            return PermissionDenied("No tienes permisos")
        
        proyecto = tarea.proyecto
        presupuesto = proyecto.presupuesto

        return Response({
            "proyecto": ProyectoSerializer(proyecto).data,
            "presupuesto": PresupuestoReadSerializer(presupuesto).data
        })
        

class TiempoTareaViewSet(viewsets.ModelViewSet):
    queryset = TiempoTarea.objects.all()
    serializer_class = TiempoTareaSerializer

    def get_permissions(self):
        # Solo el jefe puede modificar
        if self.action in ['partial_update', 'put']:
            return [EsJefe()]

        # El resto solo ver
        return [IsAuthenticated()]
    
    def perform_update(self, serializer):
       serializer.save()
       TareaService.replanificar_todo()

    def create(self, request, *args, **kwargs):
        return Response(
            {"detail": "No se pueden crear nuevas tareas"},
            status=405
        )

    def destroy(self, request, *args, **kwargs):
        return Response(
            {"detail": "No se pueden eliminar tareas"},
            status=405
        )