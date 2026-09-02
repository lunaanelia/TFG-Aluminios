import os

from geopy.distance import geodesic
from decimal import Decimal

from django.core.exceptions import ValidationError

from .models import Distancia, Presupuesto, LineaPresupuesto, OpcionSeleccionada
from proyectos.models import TipoEntrega, EstadoProyecto
from productos.models import Opcion
from usuarios.models import Usuario


class CalculoEntregaService:
    COORDENADAS_EMPRESA = (
        float(os.environ.get('COORDENADAS_EMPRESA_LAT')),
        float(os.environ.get('COORDENADAS_EMPRESA_LON'))
    )

    @staticmethod
    def calcularOpciones(lat: float, lon :float) -> dict:
       
        cliente = (lat, lon)
        
        # calcular distancia con geodesic
        distancia = geodesic(CalculoEntregaService.COORDENADAS_EMPRESA, cliente).km
        
        # vemos nuestra distancia maxima permitida para el montaje
        distancia_maxima = Distancia.objects.filter(id=1).first().distancia_maxima
        
        opciones_disponibles = [TipoEntrega.RECOGIDA, TipoEntrega.ENVIO]

        if distancia < distancia_maxima:
            opciones_disponibles.append(TipoEntrega.MONTAJE)

        return opciones_disponibles
    
    @staticmethod
    def calculoPrecioFinal(opcion: TipoEntrega, lat:float, lon:float, presupuesto) -> float:
        cliente = (lat, lon)

        distancia = geodesic(CalculoEntregaService.COORDENADAS_EMPRESA, cliente).km
        
        if opcion == TipoEntrega.ENVIO:
            precio =  20 + distancia * 0.5
        elif opcion == TipoEntrega.MONTAR:
            precio = 100 + distancia * 1.2
        
        else:
            precio = 0

class PresupuestoService:
    @staticmethod
    def crear_presupuesto(cliente:Usuario, lineas_data: list) -> Presupuesto:
        presupuesto = Presupuesto.objects.create(cliente = cliente)

        for linea_data in lineas_data:
            PresupuestoService.crear_o_actualizar_linea(presupuesto,linea_data)
            
        
        presupuesto.recalcular_total()

        return presupuesto

    @staticmethod
    def actualizar_presupuesto(instance:Presupuesto, lineas_data:list) -> Presupuesto:
        ids_payload = []

        for linea_data in lineas_data:
            linea_id = linea_data.get('id')

            if linea_id is not None:
                ids_payload.append(linea_id)

        LineaPresupuesto.objects.filter(
            presupuesto=instance
        ).exclude(
            id__in=ids_payload
        ).delete()
        
        for linea_data in lineas_data:
            linea_id = linea_data.get('id')
            linea_existente = None

            if linea_id is not None:
                linea_existente = LineaPresupuesto.objects.filter(
                    id=linea_id,
                    presupuesto=instance
                ).first() 

            PresupuestoService.crear_o_actualizar_linea(instance, linea_data, linea_existente)

        instance.refresh_from_db()
        instance.recalcular_total()
        
        instance.refresh_from_db()
        return instance

    @staticmethod
    def crear_o_actualizar_linea(presupuesto : Presupuesto, linea_data: dict, linea_existente : LineaPresupuesto = None) -> LineaPresupuesto:
        producto = linea_data['producto']
        
        opciones = linea_data['opciones_validadas']

        area = Decimal(str(linea_data['ancho'])) * Decimal(str(linea_data['alto']))

        precio_base = producto.precio_base * area

        precio_linea = precio_base

        for opcion in opciones:
            precio_linea += opcion.precio_extra

        precio_linea *= linea_data['cantidad']

        if linea_existente:

            linea_existente.producto = producto
            linea_existente.cantidad = linea_data['cantidad']
            linea_existente.ancho = linea_data['ancho']
            linea_existente.alto = linea_data['alto']

            linea_existente.precio_base = precio_base
            linea_existente.precio_final = precio_linea

            linea_existente.save()

            linea = linea_existente

        else:
            linea = LineaPresupuesto.objects.create(
                presupuesto=presupuesto,
                producto=producto,
                cantidad=linea_data['cantidad'],
                ancho=linea_data['ancho'],
                alto=linea_data['alto'],
                precio_base=precio_base,
                precio_final=precio_linea
            )
        
        OpcionSeleccionada.objects.filter(
            linea_presupuesto=linea
        ).delete()

        for opcion in opciones:

            OpcionSeleccionada.objects.create(
                linea_presupuesto=linea,
                opcion=opcion,
                precio_extra=opcion.precio_extra
            )

        return linea

    @staticmethod
    def limpiar_descatalogados(presupuesto:Presupuesto) -> Presupuesto:
        for linea in presupuesto.lineas.all():
                if not linea.producto.activo:
                    linea.delete()
                    continue

                linea.opciones_seleccionadas.filter(opcion__activo=False).delete()

        presupuesto.recalcular_total()
        return Presupuesto.objects.get(id=presupuesto.id)
    
    @staticmethod
    def puede_recalcular(presupuesto:Presupuesto) -> bool:
        if not hasattr(presupuesto, 'proyecto'):
            return True
        
        estados_validos = [
            EstadoProyecto.PENDIENTE_PAGO,
            EstadoProyecto.PENDIENTE_CITA,
            EstadoProyecto.REVISION
        ]
        
        return presupuesto.proyecto.estado in estados_validos
    
    @staticmethod
    def recalcular_si_necesario(presupuesto:Presupuesto) -> Presupuesto:
        if PresupuestoService.puede_recalcular(presupuesto):
            presupuesto.recalcular_total()
            presupuesto.refresh_from_db()
        return presupuesto
    
