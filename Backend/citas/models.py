from django.db import models
from django.core.exceptions import ValidationError

from proyectos.models import Proyecto
from usuarios.models import Usuario

class EstadoCita (models.TextChoices):
    DISPONIBLE = 'disponible', 'Disponible'
    RESERVADA = 'reservada', 'Reservada'
    COMPLETADA = 'completada', 'Completada'
    CANCELADA = 'cancelada', 'Cancelada'

class DiasCancelacion(models.Model):
    # para asegurarnos que solo haya una instancia y que sea sigleton.
    id = models.IntegerField(primary_key=True, default=1, editable=False)
    
    dias_cancelacion_cita = models.IntegerField(help_text="Días permitidos para cancelar antes de la fecha")
    
    class Meta:
        verbose_name = "Días permitidos para cancelar antes de la fecha"
        verbose_name_plural = "Días permitidos para cancelar antes de la fecha"

    def clean(self):
        # Si se intenta crear un registro nuevo estando ya el id=1 ocupado
        if DiasCancelacion.objects.exists() and self.pk != 1:
            raise ValidationError("Ya existe una configuración de dias de canelacion. Solo se permite actualizarla.")
        super().clean()

    def save(self, *args, **kwargs):
        self.id = 1  # Nos aseguramos de que siempre guarde en la misma fila
        self.full_clean()  # Ejecuta el método clean antes de guardar
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Dias de cancelacion: {self.dias_canelacion_cita}"


class Cita(models.Model):
    fecha = models.DateField()
    hora_inicio = models.TimeField()
    hora_fin = models.TimeField()

    estado = models.CharField(max_length=20, choices=EstadoCita.choices, default=EstadoCita.DISPONIBLE)
    proyecto = models.OneToOneField(
        Proyecto, 
        on_delete=models.SET_NULL,
        null = True,
        blank=True,
        related_name='cita'
    )

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='citas'
    )

    def __str__(self):
        return f"{self.fecha} {self.hora_inicio}"