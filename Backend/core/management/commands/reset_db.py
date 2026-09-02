from django.core.management.base import BaseCommand
from django.core.management import call_command

# python manage.py reset_db

class Command(BaseCommand):
    help = 'Resetea la base de datso y la reinicializa'

    def handle(self, *args, **options):

        self.stdout.write('Eliminando base de datos...')

        # Elimina migraciones y las vuelve a aplicar
        call_command('flush', '--no-input')

        self.stdout.write(self.style.SUCCESS('Base de datos limpiada'))
        
        # Reinicializa con los datos base
        call_command('init_db')
        
        self.stdout.write(self.style.SUCCESS('Reset completado'))