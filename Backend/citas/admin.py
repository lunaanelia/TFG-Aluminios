from django.contrib import admin

from .models import Cita

@admin.register(Cita)
class CitaAdmin(admin.ModelAdmin):
    list_display = ('id', 'fecha', 'hora_inicio', 'hora_fin', 'proyecto_id')
    search_fields = ('fecha', 'proyecto_id')