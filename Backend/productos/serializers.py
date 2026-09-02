from rest_framework import serializers

from .models import Producto, Caracteristica, Opcion, Recomendacion, Habitacion
from .services import ProductoService

class OpcionSerializer(serializers.ModelSerializer):
    habitaciones_recomendadas = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False,
        default=[]
    )
    habitaciones_recomendadas_data = serializers.SerializerMethodField(read_only=True)
   
    class Meta:
        model = Opcion
        fields = ['id', 'nombre', 'descripcion', 'precio_extra', 'habitaciones_recomendadas', 'habitaciones_recomendadas_data']

    def get_habitaciones_recomendadas_data(self, obj):
        return list(obj.recomendaciones.values_list('habitacion_id', flat=True))

class CaracteristicaSerializer(serializers.ModelSerializer):
    opciones = OpcionSerializer(many = True)
    
    class Meta:
        model = Caracteristica
        fields = ['id', 'nombre', 'opciones']


class ProductoSerializer(serializers.ModelSerializer):
    caracteristicas = CaracteristicaSerializer(many=True)
    
    class Meta:
        model = Producto
        fields = ['id', 'nombre', 'descripcion', 'precio_base', 'caracteristicas']
        extra_kwargs = {
            'nombre': {
                'error_messages': {
                    'unique': 'Ya existe un producto con este nombre, elige otro.'
                }
            }
        }

    # Nos aseguramos que minimo tenga una caracteristica
    def validate_caracteristicas(self, value):
        # compobamos que tenga caracterisitcas
        if not value:
            raise serializers.ValidationError("Un porducto debe tener al menos una caracterisitca.")
        
        #comprobamos que no haya caracterisitcas con nombre repetidos
        nombres = [c['nombre'].lower() for c in value]
        if len(nombres) != len(set(nombres)):
            raise serializers.ValidationError("No puedes tener caracteristicas con el mismo nombre en un mismo producto.")
        
        # comporbamos opciones de las caracterisiticas:
        for caract in value:
            opciones = caract.get('opciones', [])
            
            # Comporbamos que minimo tenga una opcnión
            if not opciones:
                raise serializers.ValidationError(f"La característica '{caract['nombre']}' debe tener al menos una opción.")
            
            # Comporbamos que entre opcinenes no hay nombre repetidos
            nombres_opc = [o['nombre'].lower().strip() for o in opciones]
            if len(nombres_opc) != len(set(nombres_opc)):
                raise serializers.ValidationError(f"En '{caract['nombre']}', no puedes repetir el nombre de las opciones.")
        
            # Comporbamos las recomendaciones solo aparazcan en una opción de la caracteristica.
            habitaciones_usuadas = set()
            
            for opcion in opciones:
                habitaciones = opcion.get('habitaciones_recomendadas',[])

                for habitacion in habitaciones:
                    if habitacion in habitaciones_usuadas:
                        raise serializers.ValidationError(f"En '{caract['nombre']}' la habitación '{habitacion}' ya tiene recomendacion.")

                    habitaciones_usuadas.add(habitacion)
        # Todo correcto
        return value
    
    def create (self, validated_data):
        return ProductoService.crear_producto(validated_data)

    def validate_nombre(self, value):
        nombre = value.strip()

        producto_existente = Producto.objects.filter(nombre__iexact=nombre)

         # Si estamos editando, excluimos el propio producto
        if self.instance:
            producto_existente = producto_existente.exclude(id=self.instance.id)

        # Si existe otro producto con ese nombre
        if producto_existente.filter(activo=True).exists():
            raise serializers.ValidationError(
                "Ya existe un producto activo con este nombre."
            )
        
        return nombre

    def update(self, instance, validated_data):
        return ProductoService.actualizar_producto(instance, validated_data)


class HabitacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Habitacion
        fields = ['id', 'nombre']


class RecomendacionSerializer(serializers.ModelSerializer):
    habitacion_nombre = serializers.CharField(
        source='habitacion.nombre',
        read_only=True
    )

    caracteristica_nombre = serializers.CharField(
        source='caracteristica.nombre',
        read_only=True
    )

    opcion_nombre = serializers.CharField(
        source='opcion.nombre',
        read_only=True
    )
    
    class Meta:
        model = Recomendacion
        fields = [
            'id', 
            'opcion', 
            'opcion_nombre',
            'habitacion',
            'habitacion_nombre',
            'caracteristica',
            'caracteristica_nombre']
        read_only_fields = ['caracteristica']
    
    def validate(self, data):
        opcion = data.get('opcion')
        habitacion = data.get('habitacion')
        caracteristica = opcion.caracteristica
        

        existe = Recomendacion.objects.filter(
                habitacion=habitacion,
                caracteristica=caracteristica
            )
        
        if self.instance:
                existe = existe.exclude(id=self.instance.id)

        if existe.exists():
            raise serializers.ValidationError( 'Ya existe una recomendación para esta característica en la habitación.')

        return data
    
    def create(self, validated_data):
        
        validated_data['caracteristica'] = (
            validated_data['opcion'].caracteristica
        )
        
        return super().create(validated_data)
    
    def update(self, instance, validated_data):

        if 'opcion' in validated_data:
            validated_data['caracteristica'] = (
                validated_data['opcion'].caracteristica
            )

        return super().update(instance, validated_data)