import holidays

from datetime import datetime, timedelta
from django.utils import timezone
from django.db import transaction

from .models import Tarea, TiempoTarea, TipoTarea, Estado
from usuarios.models import Usuario
from proyectos.models import Proyecto, EstadoProyecto, TipoEntrega
from citas.models import Cita

class TareaService:


    DIAS_SEMANA = {
        0: 'Lunes',
        1: 'Martes',
        2: 'Miercoles',
        3: 'Jueves',
        4: 'Viernes',
        5: 'Sabado',
        6: 'Domingo',
    }

    festivos_andalucia = holidays.country_holidays(
        'ES',
        subdiv='AN'
    )

    @staticmethod
    def crear_tareas_proyecto(proyecto):
    
        if Tarea.objects.filter(proyecto=proyecto).exists():
            return
        
        tiempos = {
            t.proceso: t.tiempo_estimado_horas
            for t in TiempoTarea.objects.all()
        }

        tipos_requeridos = [
            TipoTarea.CORTAR,
            TipoTarea.MECANIZAR,
            TipoTarea.MONTAR,
            TipoTarea.ENSAMBLAR
        ]

        for tipo in tipos_requeridos:
            if tipo not in tiempos:
                raise Exception(
                    f"No existe tiempo configurado para {tipo}"
                )

        # Se va a crear una tarea de todas las que hay por cada producto del
        # presupuesto

        for linea in proyecto.presupuesto.lineas.all():
            tarea_cortar = Tarea.objects.create (
                proyecto = proyecto,
                linea_presupuesto = linea,
                tipo = TipoTarea.CORTAR,
                orden  = 1,
                bloqueada = False,
                tiempo_estimado_horas = tiempos[TipoTarea.CORTAR]
            )

            tarea_mecanizar = Tarea.objects.create (
                proyecto = proyecto,
                linea_presupuesto = linea,
                tipo = TipoTarea.MECANIZAR,
                orden  = 2,
                depende_de = tarea_cortar,
                bloqueada = True,
                tiempo_estimado_horas = tiempos[TipoTarea.MECANIZAR]
            )

            tarea_montar = Tarea.objects.create (
                proyecto = proyecto,
                linea_presupuesto = linea,
                tipo = TipoTarea.MONTAR,
                orden  = 3,
                depende_de = tarea_mecanizar,
                bloqueada = True,
                tiempo_estimado_horas = tiempos[TipoTarea.MONTAR]
            )

            Tarea.objects.create (
                proyecto = proyecto,
                linea_presupuesto = linea,
                tipo = TipoTarea.ENSAMBLAR,
                orden  = 4,
                depende_de = tarea_montar,
                bloqueada = True,
                tiempo_estimado_horas = tiempos[TipoTarea.ENSAMBLAR]
            )

    @staticmethod
    def replanificar_todo():

        proyectos = Proyecto.objects.filter(
            estado__in = [
                EstadoProyecto.PRODUCCION,
                EstadoProyecto.LISTO_ENVIO,     
                EstadoProyecto.MONTAJE,
            ]
        ).order_by('fecha_confirmacion')


        Tarea.objects.filter(
            estado = Estado.PENDIENTE
        ).exclude(
            tipo = TipoTarea.MONTAJE
        ).update(
            fecha_inicio_estimada=None,
            fecha_fin_estimada=None
        )

        for proyecto in proyectos:
            TareaService._planificar_proyecto(proyecto)

    @staticmethod
    def crear_montaje(proyecto : Proyecto, trabajadores:list, fecha_inicio_estimada, fecha_fin_estimada, tiempo_estimado_horas) -> Tarea:
        nueva_tarea = Tarea.objects.create(
            proyecto=proyecto,
            tipo=TipoTarea.MONTAJE,
            estado=Estado.PENDIENTE,
            linea_presupuesto=None,
            trabajador=None,
            fecha_inicio_estimada=fecha_inicio_estimada,
            fecha_fin_estimada=fecha_fin_estimada,
            tiempo_estimado_horas=tiempo_estimado_horas
        )

        nueva_tarea.trabajadores_montaje.set(trabajadores)

        proyecto.estado = EstadoProyecto.MONTAJE
        proyecto.save()

        TareaService.replanificar_todo()

        return nueva_tarea


    @staticmethod
    @transaction.atomic
    def modificar_montaje(tarea:Tarea, trabajadores:list, fecha_inicio_estimada, fecha_fin_estimada, tiempo_estimado_horas:float) -> Tarea:
        tarea.fecha_inicio_estimada = fecha_inicio_estimada
        tarea.fecha_fin_estimada = fecha_fin_estimada
        tarea.tiempo_estimado_horas = tiempo_estimado_horas

        tarea.save()

        
        tarea.trabajadores_montaje.set(trabajadores)
        
                
        TareaService.replanificar_todo()

        return tarea
    
    @staticmethod
    @transaction.atomic
    def terminar_tarea(tarea: Tarea) -> Tarea:
        tarea.estado = Estado.TERMINADA
        tarea.fecha_fin = timezone.now()
        tarea.save()

        Tarea.objects.filter(depende_de=tarea).update(bloqueada=False)

        
        if tarea.tipo == TipoTarea.ENSAMBLAR:
            quedan = Tarea.objects.filter(
                proyecto=tarea.proyecto,
                tipo=TipoTarea.ENSAMBLAR
            ).exclude(
                estado=Estado.TERMINADA
            ).exists()

            if not quedan:
                from proyectos.services import NotificationProyectoService
                proyecto = tarea.proyecto

                if proyecto.entrega == TipoEntrega.MONTAJE:

                    proyecto.estado = EstadoProyecto.LISTO_MONTAJE
                    NotificationProyectoService.enviar_email_listo_montaje(proyecto)

                elif proyecto.entrega == TipoEntrega.ENVIO:
                    proyecto.estado = EstadoProyecto.LISTO_ENVIO
                    tiempos = TiempoTarea.objects.get(proceso=TipoTarea.PREPARAR_ENVIO)
                    # Creamos tarea de preparar envio.
                    Tarea.objects.create (
                        proyecto = proyecto,
                        tipo = TipoTarea.PREPARAR_ENVIO,
                        orden  = 5,
                        bloqueada = False,
                        tiempo_estimado_horas = tiempos.tiempo_estimado_horas
                    )
                else:
                    proyecto.estado = EstadoProyecto.LISTO_RECOGIDA
                    NotificationProyectoService.enviar_email_listo_recoger(proyecto)
                proyecto.save()

        # Para cuando terminen las tareas de montaje de un proyecto
        if tarea.tipo == TipoTarea.MONTAJE:
            quedan_dias_montaje = Tarea.objects.filter(
                proyecto=tarea.proyecto,
                tipo=TipoTarea.MONTAJE
            ).exclude(
                estado=Estado.TERMINADA
            ).exists()

            if not quedan_dias_montaje:
                proyecto = tarea.proyecto
                
                if proyecto.entrega == TipoEntrega.MONTAJE:
                    proyecto.estado = EstadoProyecto.FINALIZADO
            
                proyecto.save()


        if tarea.tipo == TipoTarea.PREPARAR_ENVIO:

            proyecto=tarea.proyecto
            # TODO DEBERIA DE SER ENVIO, PERO HAY QUE CONECTARLO CON EL ENCARGADO DE LA ENTREGA
            proyecto.estado = EstadoProyecto.FINALIZADO
            proyecto.save()
            # enviar_email_enviado()

        TareaService.replanificar_todo()
        return tarea

    @staticmethod
    @transaction.atomic
    def eliminar_montaje(tarea:Tarea) -> None:

        if tarea.tipo != TipoTarea.MONTAJE:
            raise ValueError("Solo se pueden eliminar tareas de tipo montaje")
            
        
        proyecto = tarea.proyecto

        tareas_montaje_restrantes = Tarea.objects.filter(
            proyecto=proyecto,
            tipo = TipoTarea.MONTAJE
        ).exclude(id=tarea.id).count()

        if tareas_montaje_restrantes == 0:
            proyecto.estado = EstadoProyecto.LISTO_MONTAJE
            proyecto.save()
        
        tarea.delete()
        TareaService.replanificar_todo()

    def _obtener_turnos_dia(usuario, fecha):
        nombre_dia = TareaService.DIAS_SEMANA[fecha.weekday()]

        for dia in usuario.horario:
            if dia['dia'] == nombre_dia:
                turnos = []

                for turno in dia['turnos']:
                    inicio_hora = datetime.strptime(
                        turno['inicio'],
                        '%H:%M'
                    ).time()
                    fin_hora = datetime.strptime(
                        turno['fin'],
                        '%H:%M'
                    ).time()

                    inicio = timezone.make_aware(
                        datetime.combine(fecha, inicio_hora)
                    )

                    fin = timezone.make_aware(
                        datetime.combine(fecha, fin_hora)
                    )

                    turnos.append({
                        'inicio': inicio,
                        'fin': fin
                    })
                return turnos

        return []

    def _es_festivo(fecha):
        return fecha in TareaService.festivos_andalucia

    def _quitar_reuniones(disponibilidad, usuario):
    
        if not usuario.is_boss:
            return disponibilidad

        if not disponibilidad:
            return []
        
        reuniones = Cita.objects.filter(
            usuario=usuario,
            fecha__gte = disponibilidad[0]['inicio'].date(),
            fecha__lte = disponibilidad[-1]['fin'].date()
        )

        reuniones_adaptadas = []
        for cita in reuniones:
            inicio = timezone.make_aware(datetime.combine (cita.fecha, cita.hora_inicio))
            fin = timezone.make_aware(datetime.combine (cita.fecha, cita.hora_fin))
        
            reuniones_adaptadas.append({
                'inicio': inicio,
                'fin': fin
            })

        return TareaService._restar_eventos(disponibilidad, reuniones_adaptadas)
            



    def _quitar_tareas (disponiblidad, usuario):
        tareas = Tarea.objects.filter(
            trabajador = usuario,
            estado__in = [Estado.PENDIENTE, Estado.EN_PROCESO]
        ).exclude(tipo=TipoTarea.MONTAJE)
        
        tareas_adaptadas = []

        for tarea in tareas:
            inicio = tarea.fecha_inicio if tarea.fecha_inicio else tarea.fecha_inicio_estimada
            fin = tarea.fecha_fin_estimada

            if inicio and fin:
                tareas_adaptadas.append({
                    'inicio': inicio,
                    'fin': fin
                })

        return TareaService._restar_eventos(disponiblidad, tareas_adaptadas)

    def _quitar_tareas_montaje(disponiblidad, usuario):
        tareas_montaje = Tarea.objects.filter(
            tipo = TipoTarea.MONTAJE,
            trabajadores_montaje__in = [usuario],
            estado__in = [Estado.PENDIENTE, Estado.EN_PROCESO]
        ).distinct()

        montaje_adaptados = []

        for tarea in tareas_montaje:
            inicio = tarea.fecha_inicio if tarea.fecha_inicio else tarea.fecha_inicio_estimada
            fin = tarea.fecha_fin_estimada

            if inicio and fin:
                montaje_adaptados.append({
                    'inicio': inicio,
                    'fin': fin
                })
        
        return TareaService._restar_eventos(disponiblidad, montaje_adaptados)


    def _restar_eventos(disponibilidad, eventos):
        resultado =  list(disponibilidad)

        for evento in eventos:
            inicio = evento['inicio']
            fin = evento['fin']

            nuevos_turnos_libres = []

            for bloque in resultado:
                inicio_bloque = bloque['inicio']
                fin_bloque = bloque['fin']

                if inicio< fin_bloque and fin > inicio_bloque:
                    if inicio_bloque < inicio:
                        nuevos_turnos_libres.append(
                            {
                                'inicio': inicio_bloque,
                                'fin' : inicio
                            }
                        )
                    
                    if fin_bloque > fin:
                        nuevos_turnos_libres.append(
                            {
                                'inicio': fin,
                                'fin' : fin_bloque
                            }
                        )
                else:
                    nuevos_turnos_libres.append(bloque)
            
            resultado = nuevos_turnos_libres

        resultado.sort(key=lambda x: x['inicio'])    

        return resultado

    def _generar_disponibilidad(usuario, dias=30):
        hoy = timezone.now().date()
        
        disponiblidad = []

        for i in range(dias):
            fecha = hoy + timedelta(days=i)

            if TareaService._es_festivo(fecha):
                continue

            turnos = TareaService._obtener_turnos_dia(usuario, fecha)

            if not turnos:
                continue

            disponiblidad.extend(turnos)
        
        # Quitamos reunios posibles
        disponiblidad = TareaService._quitar_reuniones(disponiblidad, usuario)
        
        # Quitamos las tareas que tengas asignadas
        disponiblidad = TareaService._quitar_tareas (disponiblidad, usuario)

        # quitamos las tareas de montaje general del proyecto
        disponiblidad = TareaService._quitar_tareas_montaje(disponiblidad, usuario)


        return disponiblidad

    def _obtener_trabajadores_validos():
        return Usuario.objects.filter(
            rol__in = ['trabajador', 'jefe'],
            is_active = True
        )

    def _buscar_hueco(disponiblidida, horas_necesarias, fecha_minima):
        
        duracion = timedelta(hours=horas_necesarias)

        for bloque in disponiblidida:
            
            if bloque['fin'] <= fecha_minima:
                continue
            
            inicio = max(bloque['inicio'], fecha_minima)
            
            fin = bloque['fin']

            tiempo_libre = fin - inicio

            if tiempo_libre >= duracion:
                return {
                    'inicio': inicio,
                    'fin': inicio + duracion
                }
        
        return None

    # devuelve el primero que este disponible
    def _buscar_mejor_trabajador(tarea, fecha_minima):
        mejor_trabajador = None
        mejor_hueco = None

        trabajadores = TareaService._obtener_trabajadores_validos()

        for trabajador in trabajadores:
            disponibilidad = TareaService._generar_disponibilidad(trabajador)

            hueco = TareaService._buscar_hueco( disponibilidad, tarea.tiempo_estimado_horas, fecha_minima)
            
            if not hueco: 
                continue
            
            if mejor_hueco is None or hueco['inicio'] < mejor_hueco['inicio']:
                mejor_hueco = hueco
                mejor_trabajador = trabajador

        if not mejor_trabajador :
            return None
        
        return {
            'trabajador': mejor_trabajador,
            'hueco' : mejor_hueco
        }

    # Creamos planificador. Ahora mismo solo debe encontrar un 
    #  hueco en la agenda, es decir,
    #       - busque el primer hueco suficiente con el mejor trabajador
    #       - asignar fecha
    #       - guardar

    def _planificar_tarea(tarea):
        
        # Tarea ya termonada o no hay que acabrla porque es de un proceso cancelado
        if tarea.estado == Estado.EN_PROCESO or tarea.estado == Estado.TERMINADA or tarea.estado == Estado.CANCELADA:
            return
        
        # Ni las tareas que son montaje
        if tarea.tipo == TipoTarea.MONTAJE:
            return
        
        fecha_minima = timezone.now()
        
        if tarea.depende_de:
            dependencia = tarea.depende_de
            if dependencia.estado == Estado.TERMINADA:
                fecha_minima = dependencia.fecha_fin
            elif dependencia.fecha_fin_estimada:
                fecha_minima = dependencia.fecha_fin_estimada
            else:
                fecha_minima = dependencia.fecha_fin_estimada

        if tarea.trabajador and (tarea.trabajador.is_boss or tarea.trabajador.is_trabajador):
            disponibilidad = TareaService._generar_disponibilidad(tarea.trabajador)
            hueco = TareaService._buscar_hueco(disponibilidad, tarea.tiempo_estimado_horas, fecha_minima)

            if hueco:
                tarea.fecha_inicio_estimada = hueco['inicio']
                tarea.fecha_fin_estimada = hueco['fin']
                tarea.save()
                return tarea
        
        resultado = TareaService._buscar_mejor_trabajador(tarea, fecha_minima)
        
        if not resultado:
            return None
        
        tarea.trabajador = resultado['trabajador']
        tarea.fecha_inicio_estimada = resultado['hueco']['inicio']
        tarea.fecha_fin_estimada = resultado['hueco']['fin']
        tarea.save()
        
        return tarea

    def _planificar_proyecto(proyecto):
        tareas = proyecto.tareas.filter(
            estado=Estado.PENDIENTE
        ).exclude(
            depende_de__estado=Estado.EN_PROCESO
        ).order_by('orden', 'id')

        tareas.update(
            fecha_inicio_estimada=None,
            fecha_fin_estimada=None
        )

        for tarea in tareas:
            TareaService._planificar_tarea(tarea)

