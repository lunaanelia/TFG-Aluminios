from django.contrib import admin

from .models import Proyecto
# Register your models here.


@admin.register(Proyecto)
class PresupuestoAdmin(admin.ModelAdmin):
    list_display = ('id', 'presupuesto_id', 'direccion_obra')
    list_filter = ['fecha_pago']
    search_fields = ['direccion_obra']



