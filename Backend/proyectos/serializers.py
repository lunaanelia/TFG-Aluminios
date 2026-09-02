from django.utils import timezone
from datetime import timedelta

from rest_framework import serializers

from .models import Proyecto
from .services import ProyectoService

from presupuestos.models import Presupuesto
   
class ProyectoSerializer(serializers.ModelSerializer):
    

    cliente_nombre = serializers.SerializerMethodField()

    presupuesto_id = serializers.IntegerField(write_only = True)
    presupuesto = serializers.PrimaryKeyRelatedField(read_only=True)
    
    fianza = serializers.DecimalField(
        source='presupuesto.fianza', 
        max_digits=10, 
        decimal_places=2, 
        read_only=True
    )

    cita = serializers.SerializerMethodField()
    
    class Meta:
        model = Proyecto
        fields = [
            'id', 
            'presupuesto_id',
            'presupuesto', 
            'estado', 
            'metodo_pago', 
            'entrega', 
            'direccion_obra', 
            'numero',
            'detalles', 
            'latitud', 
            'longitud',
            'referencia_pago',
            'fecha_pago', 
            'cliente_nombre',
            'fianza',
            'cita',
            'fecha_confirmacion',
            'fecha_limite_pago',
        ]
        
        read_only_fields = [
            'id',
            'estado',
            'fecha_pago'
        ]

    def get_cita(self, obj):
        
        if hasattr(obj, 'cita') and obj.cita:
            if hasattr(obj.cita, 'id'):
                return obj.cita.id
            
            try:
                cita_activa = obj.cita.filter(estado="RESERVADA").first()
                if cita_activa:
                    return cita_activa.id
            except AttributeError:
                cita_activa = obj.cita.all().first()
                if cita_activa:
                    return cita_activa.id

        if hasattr(obj, 'citas'):
            cita_activa = obj.citas.filter(estado="RESERVADA").first()
            if cita_activa:
                return cita_activa.id
                
        return None
    
    def get_cliente_nombre(self, obj):

        if not obj.presupuesto or not obj.presupuesto.cliente:
            return "Sin cliente asignado"
        
        cliente = obj.presupuesto.cliente

        nombre_completo = cliente.get_full_name().strip()
        if nombre_completo:
            return nombre_completo
        
        return f"Cliente (Ref: {cliente.id})"
    

    
    def validate(self, data):
        presupuesto = Presupuesto.objects.get( id=data['presupuesto_id'])

        if not presupuesto:
            raise serializers.ValidationError("El presupuesto no existe.")
        

        if hasattr(presupuesto, 'proyecto'):
            raise serializers.ValidationError("El presupuesto ya tiene proyecto.")
        
        return data
    
    def create(self, validated_data):
        return ProyectoService.crear_proyecto(validated_data)