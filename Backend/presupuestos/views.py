from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied

from core.permission import PuedeEditarPresupuesto, IsJefeOrAdmin, EsJefe, PuedeEliminarPresupuesto

from .models import Presupuesto, Distancia, Fianza
from .serializers import PresupuestoWriteSerializer, PresupuestoReadSerializer, DistanciaSerializer, CalculoEntregaSerializer, FianzaSerializer
from .services import PresupuestoService

from proyectos.models import EstadoProyecto


class DistanciaView(APIView):
    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH']:
            return [EsJefe()]
        
        return [IsAuthenticated()]
    
    def get_object(self):
        obj, created = Distancia.objects.get_or_create(id=1, defaults={'distancia_maxima': 0.0})
        return obj
    
    def get(self, request):
        serializer = DistanciaSerializer(self.get_object())
        return Response(serializer.data)

    def put(self, request):
        config = self.get_object()
        serializer = DistanciaSerializer(config, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        config = self.get_object()
        serializer = DistanciaSerializer(config, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FianzaView(APIView):
    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH']:
            return [EsJefe()]
        
        return [IsAuthenticated()]
    
    def get_object(self):
        obj, created = Fianza.objects.get_or_create(id=1, defaults={'porcentaje': 10.0})
        return obj
    
    def get(self, request):
        serializer = FianzaSerializer(self.get_object())
        return Response(serializer.data)

    def put(self, request):
        config = self.get_object()
        serializer = FianzaSerializer(config, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        config = self.get_object()
        serializer = FianzaSerializer(config, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class OpcionesEntregaView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = CalculoEntregaSerializer(data=request.query_params)

        if serializer.is_valid():
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

class PresupuestoViewSet(viewsets.ModelViewSet):
    
    permission_classes = [IsAuthenticated]
    queryset = Presupuesto.objects.all()
    serializer_class = PresupuestoReadSerializer

    def get_queryset(self):
        
        user = self.request.user
        queryset = self.queryset_base()

        if not IsJefeOrAdmin:
             # LISTADO NORMAL
            if self.action == 'list':
                return queryset.filter(cliente=user, proyecto__isnull=True)

            # PRESUPUESTOS CONFIRMADOS
            if self.action == 'confirmados':
                return queryset.filter( cliente=user, proyecto__isnull=False)

            # DETALLE
            return queryset.filter(cliente=user)

        # Es jefe

        # PRESUPUESTOS CON PROYECTO
        if self.action == 'presupuestos_proyecto':
            if not IsJefeOrAdmin:
                return queryset.none()

            return queryset.filter( proyecto__isnull=False )
        
        return queryset.filter(cliente=user)


    def queryset_base(self):
        
        return Presupuesto.objects.filter(proyecto__isnull=True).prefetch_related(
                'lineas',
                'lineas__producto',
                'lineas__opciones_seleccionadas',
                'lineas__opciones_seleccionadas__opcion'
            ).order_by('-fecha_creacion')

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()

        for presupuesto in queryset:
            PresupuestoService.recalcular_si_necesario(presupuesto)
            
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def retrieve(self, request, *args, **kwargs):

        presupuesto = Presupuesto.objects.prefetch_related(
            'lineas',
            'lineas__producto',
            'lineas__opciones_seleccionadas',
            'lineas__opciones_seleccionadas__opcion'
        ).get(id=kwargs['pk'])

        user = request.user
        tiene_proyecto = hasattr( presupuesto,'proyecto')

        if not IsJefeOrAdmin:
            if presupuesto.cliente != user:
                raise PermissionDenied('No puedes acceder a este presupuesto.')
        else:
            if (not tiene_proyecto and presupuesto.cliente != user):
                raise PermissionDenied("No puedes acceder a este presupuesto")

        PresupuestoService.recalcular_si_necesario(presupuesto)

        serializer = self.get_serializer(presupuesto)
        return Response(serializer.data)


    def get_serializer_class(self):
        if self.action in ['create','update','partial_update']:
            return PresupuestoWriteSerializer
        
        return PresupuestoReadSerializer
    
        
    def get_permissions(self):

        if self.action in ['update', 'partial_update']:
            permission_classes = [PuedeEditarPresupuesto]
        elif self.action == 'destroy':
            permission_classes = [PuedeEliminarPresupuesto]
        else:
            permission_classes = [IsAuthenticated]

        return [
            permission()
            for permission in permission_classes
        ]
    

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        presupuesto_creado = serializer.save()
        
        read_serializer = PresupuestoReadSerializer(presupuesto_creado, context={'request': request})
        return Response(read_serializer.data, status=status.HTTP_201_CREATED)
    
    def destroy(self, request, *args, **kwargs):

        presupuesto = self.get_object()

        if hasattr(presupuesto, 'proyecto'):

            raise PermissionDenied(
                "No puedes eliminar un presupuesto asociado a proyecto."
            )

        if presupuesto.cliente != request.user:

            raise PermissionDenied(
                "No puedes eliminar este presupuesto."
            )

        return super().destroy(
            request,
            *args,
            **kwargs
        )
        
    def update(self, request, *args, **kwargs):
        
        partial = kwargs.pop('partial', False)

        try:
            instance = Presupuesto.objects.prefetch_related(
                'lineas',
                'lineas__producto',
                'lineas__opciones_seleccionadas',
                'lineas__opciones_seleccionadas__opcion'
            ).get(pk=kwargs['pk'])

        except Presupuesto.DoesNotExist:
            return Response(
                {"detail": "Presupuesto no encontrado"},
                status=status.HTTP_404_NOT_FOUND
            )

        user = request.user

        if hasattr(instance, 'proyecto'):

            # Solo jefe/admin
            if not (user.is_admin or user.is_boss):
                return Response(
                    {"detail": "No tienes permiso para modificar este presupuesto"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Si el proyecto ya está en materiales
            if instance.proyecto.estado in [
                EstadoProyecto.MATERIALES,
                EstadoProyecto.PRODUCCION,
                EstadoProyecto.FINALIZADO
            ]:
                return Response(
                    {"detail": "El presupuesto ya no puede modificarse"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        else:
            # Solo el dueño
            if instance.cliente != user:
                return Response(
                    {"detail": "No puedes modificar este presupuesto"},
                    status=status.HTTP_403_FORBIDDEN
                )

        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=partial
        )

        serializer.is_valid(raise_exception=True)

        presupuesto_actualizado = serializer.save()

        read_serializer = PresupuestoReadSerializer(
            presupuesto_actualizado,
            context={'request': request}
        )

        return Response(
            read_serializer.data,
            status=status.HTTP_200_OK
        )
    
    @action(detail = True, methods=['post'])
    def limpiar_descatalogados(self, request, pk=None):
        presupuesto = self.get_object()

        tiene_proyecto = hasattr(presupuesto, 'proyecto')

        if not tiene_proyecto:
            if presupuesto.cliente != request.user:
                raise PermissionDenied(
                    "No puedes modificar este presupuesto"
                )
            
        else:
            if not (request.user.is_boss or request.user.is_admin):
                raise PermissionDenied(
                    "No tienes permisos para esta operación"
                )
            
            if presupuesto.proyecto.estado != EstadoProyecto.REVISION:
                return Response(
                    {"detail": "Solo se puede limpiar en revisión"},
                    status=400
                )
        
        presupuesto_fresco = PresupuestoService.limpiar_descatalogados(presupuesto=presupuesto)

        serializer = PresupuestoReadSerializer(presupuesto_fresco)

        return Response(serializer.data, status=status.HTTP_200_OK)


    @action(detail=False, methods=['get'])
    def confirmados(self, request):

        queryset = self.get_queryset()

        serializer = self.get_serializer(
            queryset,
            many=True
        )

        return Response(serializer.data)