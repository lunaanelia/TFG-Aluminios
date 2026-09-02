# core/permissions.py
from rest_framework import permissions
from rest_framework.permissions import SAFE_METHODS

class TienePermisos(permissions.BasePermission):
    
    # Permiso que permite crear, modificar y borrar solo al admin o jefe.
    
    def has_permission(self, request, view):
        user = request.user

        if not (user and user.is_authenticated):
            return False
        
        # Lectura (GET, HEAD , OIPTIONS) a todos
        if request.method in SAFE_METHODS:
            return True
        
        # Escritura
        return (user.is_boss or user.is_admin)
    

class PuedeEditarPresupuesto(permissions.BasePermission):
    
    def has_object_permission(self, request, view, obj):
        user = request.user

        # Debe estar autenticado
        if not (user and user.is_authenticated):
            return False

        # Empresa
        if hasattr(obj, 'proyecto'):
            return ( user.is_admin or user.is_boss)

        # solo dueño
        return obj.cliente == user

class PuedeEliminarPresupuesto(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):

        user = request.user

        if not user or not user.is_authenticated:
            return False

        # Si tiene proyecto NO se puede borrar
        if hasattr(obj, 'proyecto'):
            return False

        # Solo dueño
        return obj.cliente == user   

class IsAutenticated(permissions.BasePermission):
    def has_permission(self, request, view):
        user = request.user

        if not (user and user.is_authenticated):
                return False
        else:
            return True

class IsJefeOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        user = request.user

        if not (user and user.is_authenticated):
                return False
        
        return ( user.is_boss or user.is_admin)

class EsJefe (permissions.BasePermission):
    def has_permission(self, request, view):
        user = request.user

        if not (user and user.is_authenticated):
                return False
        
        return (user.is_boss==True)
     
class EsJefeOTrabajador(permissions.BasePermission):
    def has_permission(self, request, view, obj):
        user = request.user

        if not (user and user.is_authenticated):
                return False
        
        return (user.is_boss or user == obj.trabajador)
     