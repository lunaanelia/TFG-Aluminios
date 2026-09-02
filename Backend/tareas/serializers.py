from datetime import datetime

from django.utils import timezone

from rest_framework import serializers

from .models import Tarea, TipoTarea, Estado, TiempoTarea
from presupuestos.serializers import LineaPresupuestoReadSerializer
from usuarios.models import Usuario
from citas.models import Cita
from proyectos.models import Proyecto

class TiempoTareaSerializer(serializers.ModelSerializer):
    class Meta:
        model = TiempoTarea
        fields = ['id', 'proceso', 'tiempo_estimado_horas']

class TareaSerializer(serializers.ModelSerializer):

    proyecto_id = serializers.CharField(
        source='proyecto.id',
        read_only=True
    )

    trabajador_nombre = serializers.CharField(
        source='trabajador.first_name',
        read_only=True
    )


    linea = LineaPresupuestoReadSerializer(source = 'linea_presupuesto', read_only=True)

    direccion_obra = serializers.SerializerMethodField()
    trabajadores_nombres = serializers.SerializerMethodField()
    trabajadores_ids = serializers.SerializerMethodField()

    class Meta:
        model = Tarea

        fields = [
            'id',

            'tipo',
            'estado',
            'bloqueada',

            'orden',

            'tiempo_estimado_horas',

            'fecha_inicio',
            'fecha_fin',

            'fecha_inicio_estimada',
            'fecha_fin_estimada',

            'proyecto_id',

            'trabajador_nombre',


            'depende_de',

            'linea',

            'direccion_obra',

            'trabajadores_nombres',
            'trabajadores_ids'
        ]
    
    def get_direccion_obra(self, obj):
        if obj.tipo == TipoTarea.MONTAJE : 
            return getattr(obj.proyecto, 'direccion', 'Dirección no especificada')
        return None
    
    def get_trabajadores_nombres(self, obj):
        if obj.tipo == TipoTarea.MONTAJE : 
            request = self.context.get('request')
            return [
                u.first_name 
                for u in obj.trabajadores_montaje.all()
                if u != request.user
            ]
        return None
    
    def get_trabajadores_ids(self, obj):
        if obj.tipo == TipoTarea.MONTAJE : 
            return [u.id for u in obj.trabajadores_montaje.all()]
        return None


class TareaMontajeSerializer(serializers.Serializer):
    proyecto_id = serializers.PrimaryKeyRelatedField(
        queryset=Proyecto.objects.all(),
        source='proyecto'
    )
    
    trabajadores_ids = serializers.PrimaryKeyRelatedField(
        queryset=Usuario.objects.filter(rol__in=['trabajador', 'jefe'], is_active=True),
        source='trabajadores_montaje',
        many=True,
    )

    fecha_inicio_estimada = serializers.DateTimeField()

    fecha_fin_estimada = serializers.DateTimeField()

    tiempo_estimado_horas = serializers.FloatField()

    trabajadores_nombres = serializers.SlugRelatedField(
        many=True,
        read_only=True,
        slug_field='first_name',
        source='trabajadores_montaje'
    )


    def get_trabajadores_nombres(self, obj):
        return [
            trabajador.first_name
            for trabajador in obj.trabajadores_montaje.all()
        ]

    class Meta:
        model = Tarea

        fields = [
            'id',
            'fecha_inicio_estimada',
            'fecha_fin_estimada',
            'proyecto_id',
            'trabajadores_ids',
            'trabajadores_nombres',
            'tiempo_estimado_horas'
        ]

    def validate(self, data):

        inicio = data['fecha_inicio_estimada']
        
        fin = data['fecha_fin_estimada']

        if inicio >= fin:
            raise serializers.ValidationError("La fecha de fin debe ser posterios a la de inicio.")
        
        # No fechas pasadas
        ahora = timezone.now()

        if inicio < ahora:
            raise serializers.ValidationError("La fecha del montaje no puede ser en el pasado.")
        
        usuarios_asignados = data.get('trabajadores_montaje', [])
        
        #  comporbamos que si hay un usuario tipo jefe no tenga cita
        jefes = [
            u for u in usuarios_asignados 
            if u.rol == 'jefe'
        ]

        if jefes:
            citas = Cita.objects.filter(
               fecha__gte = inicio.date(),
               fecha__lte = fin.date()
            )

            for cita in citas:
                inicio_cita = timezone.make_aware(datetime.combine(cita.fecha, cita.hora_inicio))
                fin_cita = timezone.make_aware(datetime.combine(cita.fecha, cita.hora_fin))

                if inicio < fin_cita and fin > inicio_cita:
                    if cita.usuario in jefes:
                        raise serializers.ValidationError(
                            f"El jefe {cita.usuario.first_name} tiene una cita en ese horario."
                        )
                    
        # Comporbamos que no tenga otro montaje entre medias
        tareas_montaje = Tarea.objects.filter(
            tipo = TipoTarea.MONTAJE,
            trabajadores_montaje__in = usuarios_asignados,
            estado__in = [Estado.PENDIENTE, Estado.EN_PROCESO]
        ).distinct()

        if self.instance:
            tareas_montaje = tareas_montaje.exclude(id=self.instance.id)
        
        for tarea in tareas_montaje:
            tarea_inicio = (
                tarea.fecha_inicio
                if tarea.fecha_inicio
                else tarea.fecha_inicio_estimada
            )

            tarea_fin = tarea.fecha_fin_estimada

            if not tarea_inicio or not tarea_fin:
                continue

            # Solapamiento
            if inicio < tarea_fin and fin > tarea_inicio:
                trabajadores_conflito = tarea.trabajadores_montaje.filter(
                    id__in=[u.id for u in usuarios_asignados]
                )

                if trabajadores_conflito.exists():

                    nombres = ", ".join(
                        trabajadores_conflito.values_list(
                            'first_name',
                            flat=True
                        )
                    )

                    raise serializers.ValidationError({
                        "non_field_errors":
                        f"Los siguientes trabajadores ya tienen "
                        f"otro montaje en ese horario: {nombres}"
                    })

        return data     
