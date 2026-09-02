# from django.shortcuts import render
from django.db.models import Q
from django.utils import timezone
from datetime import timedelta

from rest_framework import viewsets , status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from core.permission import IsAutenticated, EsJefe

from .models import Cita, EstadoCita, DiasCancelacion
from .serializers import CitaSerializer, DiasCancelacionSerializer
from .services import CitaService

from proyectos.models import Proyecto
from tareas.services import TareaService

class DiasCancelacionView(APIView):
    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH']:
            return [EsJefe()]
        
        return [IsAuthenticated()]
    
    def get_object(self):
        obj, created = DiasCancelacion.objects.get_or_create(id=1, defaults={'dias_cancelacion_cita': 2})
        return obj
    
    def get(self, request):
        serializer = DiasCancelacionSerializer(self.get_object())
        return Response(serializer.data)

    def put(self, request):
        config = self.get_object()
        serializer = DiasCancelacionSerializer(config, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        config = self.get_object()
        serializer = DiasCancelacionSerializer(config, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CitaViewSet(viewsets.ModelViewSet):
    serializer_class = CitaSerializer
    permission_classes = [IsAutenticated]

    queryset = Cita.objects.all()
    
    def get_queryset(self):
        user = self.request.user
        
        queryset = Cita.objects.select_related(
            'proyecto',
            'proyecto__presupuesto',
            'proyecto__presupuesto__cliente'
        )


        if self.action == 'list':
            hoy = timezone.localdate()
            ayer = hoy - timedelta(days=1)

            queryset = queryset.filter(fecha__gte=ayer)

        if EsJefe:
            return queryset
        
        return queryset.filter( Q(estado=EstadoCita.DISPONIBLE) | Q(proyecto__presupuesto__cliente=user))
    

    def perform_create(self, serializer):
        if not self.request.user.is_boss:
            raise  PermissionDenied( "No tienes permisos")
        
        serializer.save(usuario=self.request.user)

        TareaService.replanificar_todo()

    def perform_update(self, serializer):
        cita = self.get_object()

        if cita.usuario != self.request.user:
            raise PermissionDenied(
                "No puedes modificar esta cita"
            )

        if cita.estado == EstadoCita.RESERVADA:
            raise ValueError("No puedes modificar una cita reservada")

        serializer.save()
        TareaService.replanificar_todo()

    def perform_destroy(self, instance):
        instance.delete()
        TareaService.replanificar_todo()
    
    def destroy(self, request, *args, **kwargs):
        cita = self.get_object()

        if cita.estado == EstadoCita.RESERVADA:
            return Response(
                {"error": "No puedes borrar una cita reservada."},
                status=400
            )
       
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['post'])
    def reservar(self, request, pk=None):     
        
        try:
            cita = Cita.objects.get(pk=pk)
        except Cita.DoesNotExist:
            return Response({"error": "La cita no existe."}, status=404)

        if cita.estado != EstadoCita.DISPONIBLE:
            return Response({"error" : "La cita ya no esta disponible"}, status=400)

        proyecto_id = request.data.get('proyecto_id')
       
        if not proyecto_id:
            return Response({"error": "Debes enviar proyecto_id"}, status=400)
        
        try:
            proyecto = Proyecto.objects.get( id=proyecto_id, presupuesto__cliente=request.user)

        except Proyecto.DoesNotExist:
            return Response( {"error": "Proyecto no encontrado"}, status=404)
        

        try:
            CitaService.reservar(cita=cita, proyecto=proyecto)
            return Response({"mensaje": "Cita reservada correctamente."})
        except ValueError as e:
            return Response({"error": str(e)}, status=400)
    
    

    @action(detail=True, methods=['post'])
    def cancelar(self, request, pk=None):
        cita = self.get_object()

        if not cita.proyecto:
            return Response( {"error": "La cita no está reservada."}, status=400)
        
        if cita.proyecto.presupuesto.cliente != request.user:
            return Response(
                {"error": "No puedes cancelar esta cita."},
                status=403
            )
        
        try:
            CitaService.cancelar(cita)
            return Response({
                "mensaje": "Cita cancelada."
            })
        except ValueError as e:
            return Response({"error": str(e)}, status=400)