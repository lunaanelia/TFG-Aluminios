from django.contrib import admin

from .models import Tarea


@admin.register(Tarea)
class PresupuestoAdmin(admin.ModelAdmin):
    list_display = ('id', 'proyecto', 'linea_presupuesto', 'fecha_inicio_estimada', 'fecha_fin_estimada')
    search_fields = ['id']

