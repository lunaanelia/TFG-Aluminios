import stripe

from django.conf import settings
from django.utils import timezone
from django.http import HttpResponse

from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import AllowAny
from rest_framework.exceptions import MethodNotAllowed

from .models import Proyecto, EstadoProyecto
from .serializers import ProyectoSerializer
from .services import ProyectoService

from presupuestos.models import EstadosPago
from core.permission import IsJefeOrAdmin, EsJefe
from tareas.models import TipoTarea 
from tareas.serializers import TareaSerializer

class ProyectoViewSet(viewsets.ModelViewSet):
    queryset = Proyecto.objects.all()
    serializer_class = ProyectoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        queryset = Proyecto.objects.select_related(
            'presupuesto',
            'presupuesto__cliente'
        ).exclude(
            estado = EstadoProyecto.EXPIRADO
        )

        # Caso del admin o jefe
        if IsJefeOrAdmin:
            solo_mios = self.request.query_params.get('mios')

            if solo_mios == 'true':
                return self.queryset.filter(
                    presupuesto__cliente =user,
                    activo = True
                ).exclude(
                    estado = EstadoProyecto.EXPIRADO
                )
            else:
                return queryset
            
        # caso de ser cliente / trabajador
        return queryset.filter(
            presupuesto__cliente=user,
            activo = True
        ).exclude(
            estado = EstadoProyecto.EXPIRADO
        )
    
    def get_permissions(self):
        acciones_publicas = ['pago_correcto', 'pago_cancelado', 'stripe_webhook']
        
        if self.action in acciones_publicas or 'stripe_webhook' in self.request.path:
            return [AllowAny()]
        
        return [IsAuthenticated()]
    

    def update(self, request, *args, **kwargs):
        raise MethodNotAllowed("PUT")

    def partial_update(self, request, *args, **kwargs):
        raise MethodNotAllowed("PATCH")
    
    def destroy(self, request, *args, **kwargs):
        raise MethodNotAllowed("DELETE")

    @action(detail=True, methods=['post'])
    def pagar_taller(self, request, pk=None):

        proyecto = self. get_object()
        
        if not (request.user.is_boss or request.user.is_admin):
            raise PermissionDenied(
                "No tienes permisos para registrar el pago"
            )
    

        if not proyecto.puede_pagarse :
            return Response(
                {'detail' : 'El poryecto no esta pendiente de pago o se ha pasado la fecha limite para pagar.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        proyecto.estado = EstadoProyecto.PENDIENTE_CITA
        proyecto.presupuesto.estado_pagado = EstadosPago.PAGADO
        proyecto.presupuesto.save()

        proyecto.save()

        return Response({
            'detail':'Pago en taller confirmado.',
            'estado' : proyecto.estado,
            'estado_presupuesto': (
                proyecto.presupuesto.estado_pagado
            ),
            'fecha_limite_pago': proyecto.fecha_limite_pago
        })
    
    @action(detail=True, methods=['post'])
    def crear_checkout(self, request, pk=None):
        proyecto = self.get_object()

        if proyecto.presupuesto.cliente != request.user:
            raise PermissionDenied(
                "No puedes pagar un proyecto que no es tuyo"
            )

        if proyecto.estado != EstadoProyecto.PENDIENTE_PAGO:
            return Response(
                {"detail": "El proyecto no está pendiente de pago"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        stripe.api_key = settings.STRIPE_SECRET_KEY

        session = ProyectoService.crear_checkout(proyecto=proyecto)

        return Response(
            {
                'checkout_url': session.url
            },
            status=status.HTTP_200_OK
        )

    @action(detail=False, methods=['post'])
    def stripe_webhook (self, request):
        
        payload = request.body
        sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')

        try:
            event = stripe.Webhook.construct_event(
                payload,
                sig_header,
                settings.STRIPE_WEBHOOK_SECRET
            )       
        except ValueError:
            return HttpResponse(status = 400)
        except stripe.error.SignatureVerificationError:
            return HttpResponse(status = 400)
        
        if event['type'] == 'checkout.session.completed':
            session = event['data']['object']
            proyecto_id =  session['metadata']['proyecto_id']
            payment_intent =  session['payment_intent']

            ProyectoService.proceso_pago_completado(proyecto_id, payment_intent)

        return HttpResponse(status=200)


    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def pago_correcto(self, request):
        html_content = """
        <html>
            <body style="text-align: center; font-family: sans-serif; padding-top: 50px;">
                <h1 style="color: green;">¡Pago Procesado con Éxito!</h1>
                <p>Ya puedes cerrar esta pestaña de forma segura y volver a la aplicación.</p>
            </body>
        </html>
        """
        return HttpResponse(html_content)
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def pago_cancelado(self, request):
        html_content = """
        <html>
            <body style="text-align: center; font-family: sans-serif; padding-top: 50px;">
                <h1 style="color: red;">Pago Cancelado</h1>
                <p>No se ha realizado ningún cargo. Ya puedes volver a la aplicación.</p>
            </body>
        </html>
        """
        return HttpResponse(html_content)

    @action(detail=True, methods=['post'])
    def confirmar(self, request, pk=None):
        proyecto = self.get_object()

        if not EsJefe:
            raise PermissionDenied("No tienes permisos para realizar esta acción")
        
        if proyecto.estado != EstadoProyecto.REVISION:
            return Response(
                {
                    "detail": "Solo se puede confirmar poryectos si estan en revisión"
                },
                status=status.HTTP_400_BAD_REQUEST 
            )
        
        proyecto.estado = EstadoProyecto.MATERIALES
        proyecto.fecha_confirmacion = timezone.now()
        proyecto.save()

        return Response(
            {
                "detail": "Proyecto confirmado correctamente",
                "estado": proyecto.estado
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post'])
    def materiales_pedidos(self, request, pk=None):
        proyecto = self.get_object()

        if not IsJefeOrAdmin:
            raise PermissionDenied("No tienes permisos para realizar esta acción")
        
        if proyecto.estado != EstadoProyecto.MATERIALES:
            return Response(
                {
                    "detail": "Solo se puede pedir materiales si el proyecto esta en dicho estado"
                },
                status=status.HTTP_400_BAD_REQUEST 
            )
        
        proyecto.estado = EstadoProyecto.ESPERANDO_MATERIALES
        proyecto.save()

        return Response(
            {
                "detail": "Estado del poryecto ha avanzado correctamente",
                "estado": proyecto.estado
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['post'])
    def materiales_recibidos(self, request, pk=None):
        proyecto = self.get_object()

        if not IsJefeOrAdmin:
            raise PermissionDenied("No tienes permisos para realizar esta acción")
        
        if proyecto.estado != EstadoProyecto.ESPERANDO_MATERIALES:
            return Response(
                {
                    "detail": "Este proyecto no estaba esperando materiales"
                },
                status=status.HTTP_400_BAD_REQUEST 
            )
        
        ProyectoService.materiales_recibidos(proyecto=proyecto)
        
        
        return Response(
            {
                "detail": "Estado del proyecto ha avanzado correctamente",
                "estado": proyecto.estado
            },
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['get'])
    def tareas_montaje(self, request, pk=None):
        if not IsJefeOrAdmin:
            raise PermissionDenied("No tienes permisos para realizar esta acción")
        
        proyecto = self.get_object()

        tareas = proyecto.tareas.filter(tipo=TipoTarea.MONTAJE).order_by('fecha_inicio_estimada')
        serializer = TareaSerializer(tareas, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def confirmar_recogida(self, request, pk=None):
        proyecto = self.get_object()

        if not IsJefeOrAdmin:
            raise PermissionDenied("No tienes permisos para realizar esta acción")
        
        if proyecto.estado != EstadoProyecto.LISTO_RECOGIDA:
            return Response(
                {
                    "detail": "Solo se puede confirmar poryectos si estan en revisión"
                },
                status=status.HTTP_400_BAD_REQUEST 
            )
        
        proyecto.estado = EstadoProyecto.FINALIZADO
        proyecto.save()

        return Response(
            {
                "detail": "Proyecto finalizado correctamente",
                "estado": proyecto.estado
            },
            status=status.HTTP_200_OK
        )
    

    @action(detail=True, methods=['post'])
    def cancelar(self, request, pk=None):
        proyecto = self.get_object()

        if proyecto.presupuesto.cliente != request.user:
            raise PermissionDenied("No puedes cancelar un proyecto que no sea tuyo")
        
        try:
            ProyectoService.cancelar_proyecto(proyecto)
            return Response({
                    "detail": "Proyecto cancelado correctamente.",
                    "estado": proyecto.estado
                },
                status=status.HTTP_200_OK
            )
        except ValidationError as e:
            return Response(
                {"error": str(e)},
                status=400
            )