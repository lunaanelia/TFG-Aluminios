from rest_framework import serializers

from .models import Presupuesto, LineaPresupuesto, OpcionSeleccionada, Distancia, Fianza
from .services import CalculoEntregaService, PresupuestoService

from productos.models import Producto, Opcion


class DistanciaSerializer(serializers.ModelSerializer):
    class Meta : 
        model = Distancia
        fields = ['distancia_maxima']

class FianzaSerializer(serializers.ModelSerializer):
    class Meta : 
        model = Fianza
        fields = ['porcentaje']

class OpcionEntregaSerializer(serializers.Serializer):
    id = serializers.CharField()
    label = serializers.CharField()

class CalculoEntregaSerializer(serializers.Serializer):
    lat = serializers.FloatField(write_only=True, required=True)
    lon = serializers.FloatField(write_only=True, required=True)
    
    opciones_disponibles = serializers.SerializerMethodField()

    def validate(self, data):
        lat = data['lat']
        lon = data['lon']

        opciones = CalculoEntregaService.calcularOpciones(lat, lon)
        data['opciones_entrega'] = opciones

        return data
    
    def get_opciones_disponibles(self, obj):
        opciones = self.validated_data['opciones_entrega']
        
        opciones_mapeadas = [
            {"id": op.value, "label": op.label} for op in opciones
        ]
        
        return OpcionEntregaSerializer(opciones_mapeadas, many=True).data
    

class LineaPresupuestoWriteSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False, allow_null=True)
    
    producto = serializers.PrimaryKeyRelatedField(queryset=Producto.objects.filter(activo=True))
    cantidad = serializers.IntegerField()
    
    ancho = serializers.FloatField()
    alto = serializers.FloatField()
    
    opciones = serializers.ListField(
        child=serializers.IntegerField(),
        allow_empty=True
    )

    class Meta:
        model = LineaPresupuesto
        fields = [
            'id',
            'producto',
            'cantidad',
            'ancho',
            'alto',
            'opciones'
        ]

class PresupuestoWriteSerializer(serializers.ModelSerializer):
    lineas = LineaPresupuestoWriteSerializer(many=True)
    
    class Meta:
        model = Presupuesto

        fields = [
            'id',
            'lineas'
        ]

    def validate_lineas(self, value):
        if len(value) == 0:
            raise serializers.ValidationError("Debe existir al menos una línea.")

        return value
    def _validar_opciones_producto(self, producto, opciones_ids, linea_existente =None):
        opciones = Opcion.objects.filter(id__in=opciones_ids)

        caracteristicas_producto = producto.caracteristicas.filter(activo=True)
        caracteristicas_ids = set(caracteristicas_producto.values_list('id', flat=True))
        caracteristicas_seleccionadas = set()

        for opcion in opciones:
            if not opcion.activo:
                if linea_existente:
                    existe_en_linea = OpcionSeleccionada.objects.filter(
                        linea_presupuesto=linea_existente, 
                        opcion=opcion
                    ).exists()

                    if existe_en_linea:
                        caracteristicas_seleccionadas.add(
                            opcion.caracteristica_id
                        )
                        continue
                
                raise serializers.ValidationError(f"La opción '{opcion.nombre}' está descatalogada.")
    
            caracteristica_id = opcion.caracteristica_id

            if caracteristica_id in caracteristicas_seleccionadas:
                raise serializers.ValidationError(
                    f"Has seleccionado varias opciones de la característica "
                    f"'{opcion.caracteristica.nombre}'."
                )

            caracteristicas_seleccionadas.add(caracteristica_id)

        if caracteristicas_ids != caracteristicas_seleccionadas:

            faltan = caracteristicas_ids - caracteristicas_seleccionadas

            nombres = producto.caracteristicas.filter(id__in=faltan).values_list('nombre', flat=True)
            raise serializers.ValidationError(f"Faltan opciones para: {', '.join(nombres)}")

        return opciones

    def _preparar_linea(self, linea_data, linea_existente=None):
        opciones = self._validar_opciones_producto(
            linea_data['producto'],
            linea_data['opciones'],
            linea_existente
        )
        linea_data['opciones_validadas'] = opciones
        return linea_data

    def create (self, validated_data):
        request =  self.context['request']
        
        lineas_data = validated_data.pop('lineas')
        
        lineas_preparadas = [
            self._preparar_linea(linea_data)
            for linea_data in lineas_data
        ]

        return PresupuestoService.crear_presupuesto(cliente=request.user, lineas_data=lineas_preparadas)
        
    
    def update(self, instance, validated_data):
        
        lineas_data = validated_data.pop('lineas', [])
        lineas_preparadas = []
        
        for linea_data in lineas_data:
            linea_id = linea_data.get('id')
            linea_existente = None

            if linea_id:
                linea_existente = LineaPresupuesto.objects.filter(
                    id=linea_id,
                    presupuesto=instance
                ).first()
            
            lineas_preparadas.append(
                self._preparar_linea(linea_data, linea_existente)
            )

        return PresupuestoService.actualizar_presupuesto(instance, lineas_preparadas)
    
    
class OpcionSeleccionadaReadSerializer(serializers.ModelSerializer):
    
    opcion_id = serializers.IntegerField(source='opcion.id', read_only=True)
    opcion_nombre = serializers.CharField(source='opcion.nombre', read_only=True)
    
    caracteristica_nombre = serializers.CharField(source='opcion.caracteristica.nombre', read_only=True)
    
    opcion_activa = serializers.BooleanField(source = 'opcion.activo', read_only = True)

    class Meta:
        model = OpcionSeleccionada
        fields = ['id', 'opcion_id', 'caracteristica_nombre','opcion_nombre', 'precio_extra', 'opcion_activa']


class LineaPresupuestoReadSerializer(serializers.ModelSerializer):
    producto_id = serializers.IntegerField(source='producto.id', read_only=True)
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    producto_activo = serializers.BooleanField(source='producto.activo', read_only=True)

    opciones_seleccionadas = (OpcionSeleccionadaReadSerializer(many=True,read_only=True))

    requiere_revision = serializers.SerializerMethodField()

    def get_requiere_revision(self, obj):
        if not obj.producto.activo:
            return True
        
        for opcion_sel in obj.opciones_seleccionadas.all():
            if not opcion_sel.opcion.activo:
                return True
        
        return False

    
    class Meta:
        model = LineaPresupuesto
        fields = [
            'id',
            'producto_id',
            'producto_nombre',
            'cantidad',
            'ancho',
            'alto',
            'precio_base',
            'precio_final',
            'opciones_seleccionadas',
            'producto_activo',
            'requiere_revision'
        ]

class PresupuestoReadSerializer (serializers.ModelSerializer):
    lineas = (LineaPresupuestoReadSerializer(many=True, read_only=True))

    requiere_revision = serializers.SerializerMethodField()

    def get_requiere_revision(self, obj):
        for linea in obj.lineas.all():
            if not linea.producto.activo:
                return True
            
            for opcion_sel in linea.opciones_seleccionadas.all():

                if not opcion_sel.opcion.activo:
                    return True

        return False
    
    class Meta:
        model = Presupuesto

        fields = [
            'id',
            'total',
            'fianza',
            'estado_pagado',
            'requiere_revision',
            'lineas'
        ]