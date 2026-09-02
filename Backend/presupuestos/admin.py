from django.contrib import admin
from .models import Presupuesto, LineaPresupuesto, OpcionSeleccionada

class OpcionSeleccionadaInline(admin.TabularInline):
    model = OpcionSeleccionada
    extra = 0

class LineaPresupuestoInline(admin.TabularInline):
    model = LineaPresupuesto
    extra = 0

@admin.register(Presupuesto)
class PresupuestoAdmin(admin.ModelAdmin):
    list_display = ('id', 'cliente', 'total')
    list_filter = ['fecha_creacion']
    search_fields = ['cliente__username']

    inlines = [LineaPresupuestoInline]

@admin.register(LineaPresupuesto)
class LineaPresupuestoAdmin(admin.ModelAdmin):
    list_display = ('id', 'presupuesto', 'cantidad', 'precio_final')
    
    inlines = [OpcionSeleccionadaInline]

@admin.register(OpcionSeleccionada)
class OpcionSeleccionadaAdmin(admin.ModelAdmin):
    list_display = ('id', 'linea_presupuesto', 'opcion')
    



