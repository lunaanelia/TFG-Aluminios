from rest_framework import serializers
from .models import Usuario
from .services import UsuarioService

# Consultar y editar perfiles
class UsuarioSerializer(serializers.ModelSerializer):
    
    class Meta:
        model = Usuario
        fields = ['id', 'telefono', 'email', 'rol', 'horario', 'password', 'first_name', 'last_name', 'password_pendiente']
        
        extra_kwargs = {
            'password': {'write_only': True},
            'password_pendiente':{'read_only' : True},
            'telefono' : {'validators' : []},
        }

    # crear al usuario con la contrasela encriptada
    def create(self, validated_data):
        validated_data['username'] = validated_data.get('telefono')
        user = Usuario.objects.create_user(**validated_data)
        return user

    def validate_telefono(self, value):
        existe = Usuario.objects.filter(
            telefono=value,
            is_active = True
        )

        if self.instance:
            existe = existe.exclude(id=self.instance.id)
        
        if existe.exists():
            raise serializers.ValidationError(
                "Ya existe un usuario con ese teléfono."
            )
        
        return value
    
    def update(self, instance, validated_data):
        request  = self.context.get('request')
        user = request.user

        if not user.is_boss:
            validated_data.pop('horario', None)
            validated_data.pop('rol', None)
        
        # la contraseña la tratamso a parte
        password = validated_data.pop('password', None)

        instance = super().update(instance, validated_data)

        # encripta la contraseña por eso la hemos sacado antes
        if password:
            instance.set_password(password)
            instance.save()

        return instance


# Registro publico de clientes
class RegistroClienteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['id', 'telefono', 'email', 'last_name', 'first_name', 'password']
        extra_kwargs = {
            'password': {'write_only': True},
            'telefono' : {'validators' : []},
        }

        

    def create(self, validated_data):

        try:
            return UsuarioService.registrar_cliente(validated_data)
        except ValueError as e:
           raise serializers.ValidationError({"telefono": str(e)}) 

        

# Para el listado de usuarios
class UsuarioListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['id', 'first_name', 'last_name', 'rol']