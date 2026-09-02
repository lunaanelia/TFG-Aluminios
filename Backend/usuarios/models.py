from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.validators import RegexValidator

class UsuarioManager(BaseUserManager):
        
    # Crear usuarios nosmales
    def create_user(self, telefono, password=None, **extra_fields):
        
        if not telefono:
            raise ValueError ('El telefono es obligatorio')
        
        # username va a ser el telfono
        extra_fields.setdefault ('username', telefono)
        user = self.model(telefono=telefono, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)   # guaardar el registro en la base de datos
        return user

    # Para crear los superusuarios que serán de tipo jefe
    def create_superuser(self, telefono, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)   # entrar a la web de administracion
        extra_fields.setdefault('is_superuser', True)  
        
        extra_fields.setdefault('username', telefono)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(telefono, password, **extra_fields)


class Usuario(AbstractUser):
    class Roles (models.TextChoices):
        TRABAJADOR = 'trabajador', 'Trabajador'
        CLIENTE = 'cliente', 'Cliente'
        ADMINISTRATIVO = 'administrativo', 'Administrativo'
        JEFE = 'jefe', 'Jefe'

    # Validador que el telefono solo tenga 9 números
    val_telf = RegexValidator(
        regex = r'\d{9}',
        message = "El teléfono debe tener 9 dígitos."
    )

    # Heradamos nombre, apellido y contraseña de abstradUser
    telefono = models.CharField(validators=[val_telf], max_length=9, unique=True)
    horario = models.JSONField(default=list, blank=True)
    rol = models.CharField(max_length=20, choices=Roles.choices, default=Roles.CLIENTE)
    email = models.EmailField()
    password_pendiente = models.BooleanField(default=False)

    # Como por defecto abstractUsesr tiene el campo username vamos a hacer que este sea el telefono
    USERNAME_FIELD = 'telefono'

    # Campos obligatorios al crear un superusario en terminal
    REQUIRED_FIELDS = []
    
    objects = UsuarioManager()
    
    def __str__(self):
        return f"{self.telefono} - {self.rol}"

    
    @property
    def is_boss(self):
        return self.rol == self.Roles.JEFE

    @property
    def is_admin(self):
        return self.rol == self.Roles.ADMINISTRATIVO
    
    @property
    def is_trabajador(self):
        return self.rol == self.Roles.TRABAJADOR
    
    @property
    def is_cliente(self):
        return self.rol == self.Roles.CLIENTE
    
    