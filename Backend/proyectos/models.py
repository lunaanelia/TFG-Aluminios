from django.db import models
from django.utils import timezone

from presupuestos.models import Presupuesto

class TipoEntrega(models.TextChoices):
    RECOGIDA = 'Recogida', 'recogida'
    ENVIO = 'Envio', 'envio'
    MONTAJE = 'Montar', 'montar'

class MetodoPago(models.TextChoices):
    ONLINE = 'online', 'Online'
    TALLER = 'taller', 'Taller'

class EstadoProyecto (models.TextChoices):
    PENDIENTE_PAGO = 'pendiente_pago', "Pendiente pago"
    PENDIENTE_CITA = 'pendiente_cita', 'Pendiente cita'
    REVISION = 'revision', 'Revision' 
    MATERIALES = 'materiales', 'Materiales'
    ESPERANDO_MATERIALES = 'esperando_materiales', 'Esperando materiales'
    PRODUCCION = 'produccion', 'Produccion',
    LISTO_ENVIO = 'listo_envio', 'Listo para enviar',
    LISTO_RECOGIDA = 'listo_recogida', 'Listo para recoger en el taller'
    LISTO_MONTAJE = 'listo_montaje', 'Listo para montar',
    ENVIADO = 'enviado', 'Enviado'
    MONTAJE = 'montaje', 'Montaje'
    FINALIZADO = 'finalizado', 'Finalizado'
    CANCELADO = 'cancelado', 'Cancelado',
    EXPIRADO = 'expirado', 'Expirado'

class Proyecto(models.Model):

    presupuesto = models.OneToOneField(
        Presupuesto,
        on_delete=models.PROTECT,
        related_name='proyecto'
    )

    metodo_pago = models.CharField(
        max_length=20,
        choices=MetodoPago.choices
    )

    referencia_pago = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

    estado = models.CharField(
        max_length=30,
        choices=EstadoProyecto.choices,
        default=EstadoProyecto.PENDIENTE_PAGO
    )

    fecha_creacion = models.DateTimeField(auto_now_add=True)

    fecha_pago = models.DateTimeField(
        null=True,
        blank=True
    )
    
    fecha_limite_pago = models.DateTimeField(
        null=True,
        blank=True
    )

    fecha_expiracion = models.DateTimeField()
    
    direccion_obra = models.TextField()
    latitud = models.FloatField( null=True, blank=True )
    longitud = models.FloatField( null=True, blank=True )
    numero = models.CharField(max_length=20)
    detalles = models.CharField(max_length=255, blank=True, null=True)
    
    entrega = models.CharField(
        max_length=20,
        choices=TipoEntrega.choices
    )

    fecha_confirmacion = models.DateField(null=True, blank=True)


    activo = models.BooleanField(default=True)
    
    def __str__(self):
       return f"Proyecto {self.id}" 
    
    @property
    def puede_pagarse(self):
        if self.estado != EstadoProyecto.PENDIENTE_PAGO:
            return False
        
        if not self.fecha_limite_pago:
            return False

        return timezone.now() <= self.fecha_limite_pago

