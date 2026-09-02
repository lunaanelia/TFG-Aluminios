from django.utils import timezone

from rest_framework import serializers

from .models import Cita, DiasCancelacion

class DiasCancelacionSerializer(serializers.ModelSerializer):
    class Meta : 
        model = DiasCancelacion
        fields = ['dias_cancelacion_cita']

class CitaSerializer(serializers.ModelSerializer):
    proyecto_id = serializers.IntegerField(
        source='proyecto.id',
        read_only=True
    )
    cliente_nombre = serializers.SerializerMethodField()
    reservada = serializers.SerializerMethodField()

    usuario_nombre = serializers.CharField(
        source = 'usuario.first_name',
        read_only=True
    )

    class Meta:
        model = Cita
        fields = ['id', 'fecha', 'hora_inicio', 'hora_fin', 'estado', 'proyecto_id', 'cliente_nombre', 'reservada', 'usuario_nombre']
        read_only_fields = ['estado']

    def get_cliente_nombre(self, obj):
        if not obj.proyecto:
            return None
        
        cliente = obj.proyecto.presupuesto.cliente

        nombre_completo = cliente.get_full_name().strip()
        
        return nombre_completo
    
    def get_reservada(self, obj):
        return obj.proyecto is not None

    def validate(self, data):
        fecha = data['fecha']
        hora_inicio = data['hora_inicio']
        hora_fin = data['hora_fin']

        if hora_inicio >= hora_fin:
            raise serializers.ValidationError("La hora de inicio comenzar antes que la de fin")
        

        citas_solapadas = Cita.objects.filter(
            fecha = fecha,
            hora_inicio__lt=hora_fin,
            hora_fin__gt=hora_inicio
        )

        if self.instance:
            citas_solapadas = citas_solapadas.exclude(id=self.instance.id)

        if citas_solapadas.exists():
            raise serializers.ValidationError("Ya existe una cita en ese tramo horario.")
        
        return data
    
    def validate_fecha(self, value):
        hoy = timezone.localdate()

        if value <= hoy:
            raise serializers.ValidationError("La cita debe ser posteriror al día de hoy.")
        
        return value