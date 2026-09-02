from django.db import models

from proyectos.models import Proyecto
from presupuestos.models import LineaPresupuesto
from usuarios.models import Usuario


class TipoTarea (models.TextChoices):
    CORTAR = 'cortar', 'Cortar'
    MECANIZAR = 'mecanizar', 'Mecanizar'
    MONTAR = 'montar', 'Montar'
    ENSAMBLAR = 'ensamblar', 'Ensamblar'
    MONTAJE = 'montaje', 'Montaje'
    PREPARAR_ENVIO = 'preparar_envio', 'Preparar envio',

class Estado (models.TextChoices):
        PENDIENTE = 'pendiente'
        EN_PROCESO = 'en_proceso'
        TERMINADA = 'terminada'
        CANCELADA = 'candelada'

class TiempoTarea(models.Model):
    proceso = models.CharField(
        max_length=20,
        choices=TipoTarea.choices,
        unique=True
    )

    tiempo_estimado_horas = models.FloatField()

    def __str__(self):
        return f"{self.proceso} - {self.tiempo_estimado_horas}h"

class Tarea(models.Model):

    proyecto = models.ForeignKey(
        Proyecto,
        related_name = 'tareas',
        on_delete = models.CASCADE
    )

    linea_presupuesto = models.ForeignKey(
        LineaPresupuesto,
        related_name='tareas',
        on_delete=models.CASCADE,
        null = True,
        blank = True
    )

    tipo = models.CharField(
        max_length=20,
        choices=TipoTarea.choices
    )

    estado = models.CharField(
        max_length=20, 
        choices=Estado.choices,
        default=Estado.PENDIENTE
    )

    trabajador = models.ForeignKey(
        Usuario,
        null=True,
        blank=True,
        on_delete=models.SET_NULL
    )

    trabajadores_montaje = models.ManyToManyField(
        Usuario,
        blank=True,
        related_name = 'tareas_grupales'
    )

    tiempo_estimado_horas = models.FloatField()

    orden = models.IntegerField(default=0)

    depende_de = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.SET_NULL
    )

    bloqueada = models.BooleanField(default=False)

    fecha_inicio_estimada = models.DateTimeField(
        null=True,
        blank=True
    )

    fecha_fin_estimada = models.DateTimeField(
        null=True,
        blank=True
    )

    fecha_inicio = models.DateTimeField(
        null=True,
        blank=True
    )

    fecha_fin = models.DateTimeField(
        null=True,
        blank=True
    )
