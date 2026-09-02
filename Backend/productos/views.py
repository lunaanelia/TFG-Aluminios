from django.db.models import Prefetch

from rest_framework import viewsets
from rest_framework.response import Response

from .models import Producto, Opcion, Caracteristica, Habitacion, Recomendacion
from .serializers import ProductoSerializer, HabitacionSerializer, RecomendacionSerializer
from .services import ProductoService

from core.permission import TienePermisos, IsAutenticated, EsJefe

class ProductoViewSet(viewsets.ModelViewSet):
    queryset = Producto.objects.all()   
    serializer_class = ProductoSerializer

    permission_classes = [TienePermisos]

    # solo devolvemos lo que este activo
    def get_queryset(self):
        # Nos quedamso con las opcines filtadas
        opciones_activas = Opcion.objects.filter(activo=True)

        # nos quedamos con las opcines activas de las caracterisircas activas
        caracteristica_activas = Caracteristica.objects.filter(
            activo=True
        ).prefetch_related(
            Prefetch('opciones', queryset=opciones_activas)
        )

        # Solo mostrarmos los porductos activos
        return Producto.objects.filter(activo=True).prefetch_related (Prefetch ('caracteristicas', queryset=caracteristica_activas))
    
    # Sobre escribimos el delete para que no borre del todo, si que cambie el estado de activo a desactivo
    def destroy(self, request, *args, **kwargs):
        producto = self.get_object()
        
        desactivado = ProductoService.eliminar_producto(producto)
        
        if desactivado:
            return Response({"detail": "Producto desactivado."}, status=200)
        
        return Response(status=204)
       
class HabitacionViewSet(viewsets.ModelViewSet):
    queryset = Habitacion.objects.all()
    serializer_class = HabitacionSerializer

    def get_permissions(self):
        if self.action in ['create', 'destroy', 'patch', 'put']:
            return [EsJefe()]
        
        return [IsAutenticated()]

class RecomendacionViewSet(viewsets.ModelViewSet):
    queryset = Recomendacion.objects.select_related(
        'habitacion',
        'caracteristica',
        'opcion'
    )

    serializer_class = RecomendacionSerializer

    permission_classes = [TienePermisos]