from unittest.mock import patch

from datetime import datetime
from django.test import TestCase
from django.utils import timezone

from .services import TareaService
from .models import Tarea
from usuarios.models import Usuario

class BuscarHuecoTests(TestCase):

    # Prueba que comprueba si hay hueco
    def test_busca_hueco_correctamente(self):

        # creamos un hueco en la agenda
        inicio = timezone.make_aware(datetime(2026, 7, 20, 9, 0))
        fin = timezone.make_aware(datetime(2026, 7, 20, 14, 0))

        disponibilidad = [
            {
                "inicio": inicio,
                "fin": fin
            }
        ]

        fecha_minima = inicio

        # Ejecutamos la función
        resultado = TareaService._buscar_hueco(
            disponibilidad,
            horas_necesarias=2,
            fecha_minima=fecha_minima
        )

        # comprouba que haya devuleto un hueco
        self.assertIsNotNone(resultado)

        # comprueba que la tarea comieza a las 9 (hora del hueco creado)
        self.assertEqual(
            resultado["inicio"],
            inicio
        )

        # comprueba que la tarea acaba dos horas despues
        self.assertEqual(
            resultado["fin"],
            timezone.make_aware(
                datetime(2026, 7, 20, 11, 0)
            )
        )

    # Prueba no existe hueco suficeinte
    def test_no_hueco_suficiente(self):
    
        disponibilidad = [
            {
                "inicio": timezone.make_aware(datetime(2026, 7, 20, 9, 0)),
                "fin": timezone.make_aware(datetime(2026, 7, 20, 10, 0))
            },
            {
                "inicio": timezone.make_aware(datetime(2026, 7, 20, 11, 0)),
                "fin": timezone.make_aware(datetime(2026, 7, 20, 12, 0))
            }
        ]

        resultado = TareaService._buscar_hueco(
            disponibilidad,
            horas_necesarias=2,
            fecha_minima=timezone.make_aware(datetime(2026, 7, 20, 9, 0))
        )

        self.assertIsNone(resultado)

    def test_fecha_minima(self):
        inicio = timezone.make_aware(datetime(2026, 7, 20, 9, 0))
        fin = timezone.make_aware(datetime(2026, 7, 20, 14, 0))
        fecha_minima = timezone.make_aware(datetime(2026, 7, 20, 11, 30))
        
        disponibilidad = [
            {
                "inicio": inicio,
                "fin": fin
            }
        ]

        fecha_minima = inicio

        resultado = TareaService._buscar_hueco(
            disponibilidad,
            horas_necesarias=2,
            fecha_minima=fecha_minima
        )
        
        self.assertIsNotNone(resultado)

        self.assertEqual(
            resultado["inicio"],
            fecha_minima
        )

   