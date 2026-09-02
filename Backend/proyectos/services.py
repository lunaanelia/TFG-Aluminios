import stripe
import os

from dotenv import load_dotenv

from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.core.mail import send_mail

from datetime import timedelta

from .models import EstadoProyecto, Proyecto, MetodoPago
from presupuestos.models import Presupuesto, EstadosPago
from citas.models import Cita, EstadoCita
from tareas.models import Tarea, Estado

from tareas.services import TareaService

class NotificationProyectoService:
    
    @staticmethod
    def enviar_email_listo_montaje(proyecto):
        cliente = proyecto.presupuesto.cliente

        send_mail(
            subject='Tu pedido esta listo para montar',
            message=(
                f'Hola {cliente.first_name},\n\n'
                f'Tu pedido esta listo para programar el montaje.\n'
                f'Nos pondremos en contacto con usted pronto\n\n'
                f'En el caso de que pasen 5 días de este mensaje y nadei haya contactado con usted, porfavor llamenos.\n\n'
                f'Este mensaje se ha generado por defecto, por favor no conteste a este.'
            ),

            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[cliente.email],
            fail_silently=False
        )

    @staticmethod
    def enviar_email_listo_recoger(proyecto):
        
        cliente = proyecto.presupuesto.cliente

        send_mail(
            subject='Tu pedido esta listo para recoger',
            message=(
                f'Hola {cliente.first_name},\n\n'
                f'Tu pedido esta listo para recoger.\n'
                f'Puedes pasar en el horario de apertura. En el caso de no poder contacte con nosotros.\n\n'
                f'Gracias.\n\n'
                f'Este mensaje se ha generado por defecto, por favor no conteste a este.'
            ),

            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[cliente.email],
            fail_silently=False
        )

    @staticmethod
    def enviar_email_enviado(proyecto):
        
        cliente = proyecto.presupuesto.cliente

        send_mail(
            subject='Tu pedido ha sido enviado',
            message=(
                f'Hola {cliente.first_name},\n\n'
                f'Tu pedido ha sido enviado lo recibira en breves\n\n'
                f'Gracias.\n\n'
                f'Este mensaje se ha generado por defecto, por favor no conteste a este.'
            
            ),

            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[cliente.email],
            fail_silently=False
        )

class ProyectoService:
    @staticmethod
    def cancelar_proyecto(proyecto : Proyecto) -> None:
        if proyecto.estado in [
            EstadoProyecto.ESPERANDO_MATERIALES,
            EstadoProyecto.PRODUCCION,
            EstadoProyecto.LISTO_ENVIO,
            EstadoProyecto.LISTO_MONTAJE,
            EstadoProyecto.LISTO_RECOGIDA,
            EstadoProyecto.ENVIADO,
            EstadoProyecto.MONTAJE,
            EstadoProyecto.FINALIZADO,
            EstadoProyecto.CANCELADO
        ]:
            raise ValidationError("Este proyecto ya no se puede cancelar")
        

        if proyecto.estado in [
            EstadoProyecto.PENDIENTE_CITA,
        ]:
            ProyectoService.devolver_fianza(proyecto)

        
        ProyectoService.liberar_cita(proyecto)
        
        proyecto.estado = EstadoProyecto.CANCELADO
        proyecto.save()  

    @staticmethod
    def crear_proyecto(validated_data:dict) -> Proyecto:
        presupuesto_id = validated_data.pop('presupuesto_id')
        presupuesto = Presupuesto.objects.get(id=presupuesto_id)

        proyecto = Proyecto.objects.create(
            presupuesto=presupuesto,
            fecha_limite_pago = timezone.now() + timedelta(days=10),
            fecha_expiracion = timezone.now() + timedelta(days=15),
            **validated_data
        )

        presupuesto.estado_pago = EstadosPago.PROCESANDO
        presupuesto.save()
        
        return proyecto

    @staticmethod
    def liberar_cita(proyecto:Proyecto) -> None:
        if not hasattr(proyecto, 'cita'):
            return

        cita = proyecto.cita

        cita.proyecto = None
        
        if cita.fecha > timezone.now().date():
            cita.estado = EstadoCita.DISPONIBLE
            cita.save() 

    @staticmethod
    def devolver_fianza(proyecto : Proyecto) -> None:
        if proyecto.metodo_pago == MetodoPago.ONLINE and proyecto.referencia_pago:
            stripe.api_key = settings.STRIPE_SECRET_KEY
           
            try:
                refund = stripe.Refund.create(
                    payment_intent=proyecto.referencia_pago
                )

                print(f"Refund creada: {refund.id}")
                print(f"Estado: {refund.status}")

            except stripe.error.StripeError as e:
                print(e.user_message)

    @staticmethod
    def cancelar_tareas(proyecto : Proyecto) -> None:
        Tarea.objects.filter(
            proyecto=proyecto,
            estado__in=[Estado.PENDIENTE, Estado.EN_PROCESO]
        ).update(
            estado=Estado.CANCELADA
        )

        TareaService.replanificar_todo()
    
    @staticmethod
    def materiales_recibidos(proyecto : Proyecto) -> None:
        proyecto.estado = EstadoProyecto.PRODUCCION
        proyecto.save()

        TareaService.crear_tareas_proyecto(proyecto)
        TareaService.replanificar_todo()

    @staticmethod
    def crear_checkout(proyecto:Proyecto):

        load_dotenv() 

        return stripe.checkout.Session.create(

            payment_method_types=['card'],

            mode='payment',

            line_items=[
                {
                    'price_data': {
                        'currency': 'eur',

                        'product_data': {
                            'name': f'Proyecto #{proyecto.id}',
                        },

                        'unit_amount': int(
                            proyecto.presupuesto.fianza * 100
                        ),
                    },

                    'quantity': 1,
                }
            ],


            success_url = os.environ.get('SUCCESS_URL'),

            cancel_url = os.environ.get('CANCEL_URL'),

            metadata={
                'proyecto_id': proyecto.id,
            }
        )
    
    @staticmethod
    def proceso_pago_completado (proyecto_id : str, payment_intent:str) -> None:
        proyecto = Proyecto.objects.get(id=proyecto_id)

        proyecto.estado = EstadoProyecto.PENDIENTE_CITA
        proyecto.fecha_pago = timezone.now()
        proyecto.referencia_pago = payment_intent

        proyecto.presupuesto.estado_pagado = EstadosPago.PAGADO
        proyecto.presupuesto.save()

        proyecto.save()
    