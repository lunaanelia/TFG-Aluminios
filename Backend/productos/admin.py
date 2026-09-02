from django.contrib import admin

from .models import Producto, Caracteristica, Opcion, Recomendacion

class RecomendacionInline(admin.TabularInline):
    model = Recomendacion
    extra = 0
    readonly_fields = ('caracteristica',)

class OpcionInline(admin.TabularInline):
    model = Opcion
    extra = 0
    show_change_link = True # Permite ir a la edición de la opción

class CaracteristicaInline(admin.TabularInline):
    model = Caracteristica
    extra = 0
    show_change_link = True

@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ('id', 'nombre', 'precio_base', 'descripcion', )
    search_fields = ('nombre', 'descripcion')
    inlines = [CaracteristicaInline]


@admin.register(Caracteristica)
class CaracteristicaAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'producto')
    inlines = [OpcionInline]

@admin.register(Opcion)
class OpcionAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'caracteristica', 'precio_extra')
    inlines = [RecomendacionInline]