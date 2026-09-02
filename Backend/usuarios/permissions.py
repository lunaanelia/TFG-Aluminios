from rest_framework import permissions

class EsJefe(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_boss)


class EsPropioOEsJefe(permissions.BasePermission):
   
    def has_permission(self, request, view):
        return request.user.is_authenticated
        
    def has_object_permission(self, request, view, obj):
        return obj == request.user or request.user.is_boss