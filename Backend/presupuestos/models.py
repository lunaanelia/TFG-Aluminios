from decimal import Decimal

from django.db import models
from django.core.exceptions import ValidationError

from usuarios.models import Usuario
from productos.models import Producto, Opcion

class EstadosPago (models.TextChoices):
    SIN_PAGAR = 'sin_pagar', 'Sin pagar'
    PROCESANDO = 'procesando', 'Procesando pago'
    PAGADO = 'pagado', 'Pagado',
    FALLIDO = 'fallido', 'Fallido'

class Distancia(models.Model):
    # para asegurarnos que solo haya una instancia y que sea sigleton.
    id = models.IntegerField(primary_key=True, default=1, editable=False)
    
    distancia_maxima = models.FloatField(help_text="Distancia máxima permitida en km")
    
    class Meta:
        verbose_name = "Configuración de Distancia"
        verbose_name_plural = "Configuración de Distancia"

    def clean(self):
        # Si se intenta crear un registro nuevo estando ya el id=1 ocupado
        if Distancia.objects.exists() and self.pk != 1:
            raise ValidationError("Ya existe una configuración de distancia. Solo se permite actualizarla.")
        super().clean()

    def save(self, *args, **kwargs):
        self.id = 1  # Nos aseguramos de que siempre guarde en la misma fila
        self.full_clean()  # Ejecuta el método clean antes de guardar
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Distancia Máxima: {self.distancia_maxima} km"


class Fianza(models.Model):
    # para asegurarnos que solo haya una instancia y que sea sigleton.
    id = models.IntegerField(primary_key=True, default=1, editable=False)
    
    porcentaje = models.FloatField(help_text="porcentaje que se paga de fianza (%)")
    
    class Meta:
        verbose_name = "Configuración de Fianza"
        verbose_name_plural = "Configuración de Fianza"

    def clean(self):
        # Si se intenta crear un registro nuevo estando ya el id=1 ocupado
        if Fianza.objects.exists() and self.pk != 1:
            raise ValidationError("Ya existe una configuración de fianza. Solo se permite actualizarla.")
        super().clean()

    def save(self, *args, **kwargs):
        self.id = 1  # Nos aseguramos de que siempre guarde en la misma fila
        self.full_clean()  # Ejecuta el método clean antes de guardar
        super().save(*args, **kwargs)

    def __str__(self):
        return f"FIANZA : {self.porcentaje} %"


class Presupuesto(models.Model):
    
    cliente = models.ForeignKey(Usuario, on_delete = models.PROTECT, related_name='presupuestos')

    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    estado_pagado = models.CharField(max_length=20, choices=EstadosPago.choices, default=EstadosPago.SIN_PAGAR)

    total = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    fianza = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    def recalcular_total(self):
        
        total = Decimal('0.00')

        for linea in self.lineas.all():
            
            # Producto descatalogado, no cuenta para el total.
            if not linea.producto.activo:
                continue
            
            area = Decimal(str(linea.ancho)) * Decimal(str(linea.alto))
            
            precio_m2 = Decimal(str(linea.producto.precio_base)) * area
            
            precio_total_m2 = precio_m2

            for opcion_sel in linea.opciones_seleccionadas.all():
                
                # Opcion no disponible
                if not opcion_sel.opcion.activo:
                    continue    
                
                precio_extra = Decimal(str(opcion_sel.opcion.precio_extra))
                opcion_sel.precio_extra = precio_extra
                opcion_sel.save()

                precio_total_m2 += precio_extra

            precio_linea = Decimal(str(linea.cantidad)) * precio_total_m2

            linea.precio_base = precio_m2
            linea.precio_final = precio_linea
            linea.save()

            total += precio_linea
        
        self.total = total

        if self.estado_pagado == EstadosPago.SIN_PAGAR:
            porcentaje = Fianza.objects.filter(id=1).first().porcentaje
            porcentaje_decimal = Decimal(str(porcentaje)) / Decimal('100')
            self.fianza = total * porcentaje_decimal
        
        
        self.save()

        return total


    def __str__(self):
        return f"Presupuesto {self.id}"
    

class LineaPresupuesto(models.Model):
    presupuesto = models.ForeignKey(
        Presupuesto,
        on_delete=models.CASCADE,
        related_name='lineas'   
    )

    producto = models.ForeignKey(
        Producto,
        on_delete=models.PROTECT
    )

    cantidad = models.PositiveIntegerField(default=1)

    ancho = models.FloatField()
    alto = models.FloatField()

    precio_base = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    precio_final = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    def __str__(self):
        return f"{self.producto.nombre}"
    
class OpcionSeleccionada(models.Model):
    linea_presupuesto = models.ForeignKey(
        LineaPresupuesto,
        on_delete=models.CASCADE,
        related_name='opciones_seleccionadas'
    )

    opcion = models.ForeignKey(
        Opcion,
        on_delete=models.PROTECT
    )

    precio_extra = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    def __str__(self):
        return self.opcion.nombre