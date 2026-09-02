from datetime import date

from django.core.exceptions import ValidationError

from .models import Cita, EstadoCita, DiasCancelacion
from proyectos.models import Proyecto, EstadoProyecto


class CitaService:
    @staticmethod
    def reservar(cita: Cita, proyecto:Proyecto) -> Cita:
        if cita.estado != EstadoCita.DISPONIBLE:
            raise ValueError("La cita ya no esta disponible")


        if hasattr(proyecto, 'cita'):
            raise ValueError ("Este proyecto ya tiene una cita asignada.")
        

        
        cita.proyecto = proyecto
        cita.estado = EstadoCita.RESERVADA
        cita.save()

        proyecto.estado = EstadoProyecto.REVISION
        proyecto.save()

        return cita
    
    @staticmethod
    def cancelar(cita:Cita)->Cita:
        if not cita.proyecto:
            return ValueError("La cita no está reservada.")
        
        
        dias_minimos = DiasCancelacion.objects.filter(id=1).first().dias_cancelacion_cita
        dias_restantes = (cita.fecha - date.today()).days

        if dias_restantes < dias_minimos:
            raise ValueError(f"Debes cancelar con {dias_minimos} días de antelación.")
        
        proyecto = cita.proyecto
        cita.proyecto = None
        cita.estado = EstadoCita.DISPONIBLE
        cita.save()

        proyecto.estado = EstadoProyecto.PENDIENTE_CITA
        proyecto.save()
