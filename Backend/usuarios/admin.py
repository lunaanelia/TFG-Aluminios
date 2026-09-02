from django.contrib import admin

from .models import Usuario 

@admin.register(Usuario)
class UsuarioAdmin(admin.ModelAdmin):
    list_display = ('id', 'first_name', 'last_name', 'email', 'rol')
    search_fields = ('first_name', 'last_name', 'email')