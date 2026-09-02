from django.db import models
from django.db.models import Q

class Producto(models.Model):
    
    nombre = models.CharField(max_length = 100)
    descripcion = models.TextField(blank=True, default="")
    precio_base = models.DecimalField(max_digits = 10, decimal_places=2)
    activo = models.BooleanField(default=True)
    
    class Meta:
         constraints = [
            models.UniqueConstraint(
                fields=['nombre'],
                condition=Q(activo=True),
                name='unique_producto_activo'
            )
        ]
    
    def save(self, *args, **kwargs):

        super().save(*args, **kwargs)

        if not self.activo:
            self.caracteristicas.update(activo=False)

            for caracteristica in self.caracteristicas.all():
                caracteristica.opciones.update(activo=False)
    
    def __str__(self):
        return self.nombre


class Caracteristica(models.Model):
    producto = models.ForeignKey(
        Producto,
        on_delete=models.CASCADE,
        related_name = 'caracteristicas'
    )

    nombre = models.CharField(max_length = 100)
    activo = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.nombre} ({self.producto.nombre})"
    
    class Meta:
        constraints = [ models.UniqueConstraint(
            fields=['producto', 'nombre'],
            name = 'unique_caracteristica_producto'
        )]
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

        if not self.activo:
            self.opciones.update(activo=False)

class Opcion(models.Model):

    caracteristica = models.ForeignKey(
        Caracteristica,
        on_delete=models.CASCADE,
        related_name = 'opciones'
    )

    nombre = models.CharField(max_length = 100)
    precio_extra = models.DecimalField(max_digits = 10, decimal_places=2, default=0)
    descripcion = models.TextField(blank=True, default="")
    activo = models.BooleanField(default=True)
   

    def __str__(self):
        return f"{self.nombre}"
    
    class Meta:
        constraints = [ models.UniqueConstraint(
            fields=['caracteristica', 'nombre'],
            name = 'unique_opcion_caracteristica'
        )]


class Habitacion (models.Model):
    nombre = models.CharField(max_length=50, unique=True)
    
    def __str__(self):
        return self.nombre

class Recomendacion(models.Model):
    
    opcion = models.ForeignKey(
        Opcion,
        on_delete=models.CASCADE,
        related_name='recomendaciones'
    )

    caracteristica = models.ForeignKey(
        Caracteristica,
        on_delete = models.CASCADE,
        editable = False
    )

    habitacion = models.ForeignKey(
        Habitacion,
        on_delete=models.CASCADE,
        related_name='recomendaciones'
    )

    class Meta:
        # Asegurarno de que por habitación solo haya una opción recomendad de la carcteristica
        constraints = [
            models.UniqueConstraint(
                fields=['caracteristica', 'habitacion'],
                name='una_recomendacion_por_habitacion'
            )
        ]

    def save(self, *args, **kwargs):
        self.caracteristica = self.opcion.caracteristica
        super().save(*args, **kwargs)
    
