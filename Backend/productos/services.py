from django.db import transaction

from .models import Producto, Caracteristica, Opcion, Recomendacion
from presupuestos.models import LineaPresupuesto

class ProductoService:
    @staticmethod
    @transaction.atomic
    def crear_producto(validated_data: dict) -> Producto:
        caracteristicas_data = validated_data.pop('caracteristicas')
        
        nombre_producto = validated_data['nombre'].strip()

        producto_existente  = Producto.objects.filter(
            nombre__iexact=nombre_producto,
            activo = False
        ).first()

       
        # Si existe y no esta activo, lo activamos u actualizamos
        if producto_existente:
            producto = producto_existente
            producto.descripcion = validated_data.get('descripcion', producto.descripcion)
            producto.precio_base =  validated_data.get('precio_base', producto.precio_base)
            producto.activo = True
            producto.save()

            for caracteristica in producto.caracteristicas.all():
                caracteristica.activo = False
                caracteristica.save()
                
        else: # Crear producto
            producto = Producto.objects.create(**validated_data)
            
        
        for caracteristica_data in caracteristicas_data:
            
            opciones_data = caracteristica_data.pop('opciones')
            
            if not opciones_data:
                raise ValueError("La caracterisitca '{caracteristica_data['nombre']}' debe tener al menos una opcion")
            
            caracteristica_nombre = caracteristica_data['nombre'].strip()
           
            caracteristica_existe = Caracteristica.objects.filter(
                    producto=producto,
                    nombre__iexact=caracteristica_nombre,
                ).first()
            
            if(caracteristica_existe):
               caracteristica = caracteristica_existe
               caracteristica.activo = True
               caracteristica.save() 

            else:  # Crear característica
                caracteristica = Caracteristica.objects.create(
                    producto=producto,
                    **caracteristica_data
                )

            # creamos la opciones
            for opcion_data in opciones_data:
                habitaciones_ids = opcion_data.pop(
                    'habitaciones_recomendadas',
                    []
                )

                opcion_nombre = opcion_data['nombre'].strip()
                
                opcion_existente = Opcion.objects.filter(
                    caracteristica=caracteristica,
                    nombre__iexact=opcion_nombre,
                   
                ).first()

                if opcion_existente:
                    opcion.descripcion = opcion_data.get('descripcion', opcion.descripcion)
                    opcion.precio_extra = opcion_data.get('precio_extra', opcion.precio_extra)
                    opcion.activo = True
                    opcion.save()
                else:
                    opcion = Opcion.objects.create(
                        caracteristica=caracteristica,
                        **opcion_data
                    )
                
                Recomendacion.objects.filter(opcion=opcion).delete()
                for habitacion_id in habitaciones_ids:
                    Recomendacion.objects.create(
                        opcion=opcion,
                        habitacion_id=habitacion_id,
                        caracteristica=caracteristica
                    )

        return producto

    @staticmethod
    @transaction.atomic
    def actualizar_producto(instance: Producto, validated_data : dict) -> Producto:
        caracteristicas_data = validated_data.pop('caracteristicas', [])

        # Actualización del producto
        instance.nombre = validated_data.get('nombre', instance.nombre)
        instance.descripcion = validated_data.get('descripcion', instance.descripcion)
        instance.precio_base = validated_data.get('precio_base', instance.precio_base)
        instance.save()

        # Actualizacion de caracteristicas
        caracteristicas_ids = []

        for c_data in caracteristicas_data:
            
            opciones_data = c_data.pop('opciones', [])

            c_nombre = c_data['nombre'].strip()

            caracteristica = (
                Caracteristica.objects.filter(
                    producto = instance,
                    nombre = c_nombre,
                    activo = True
                ).first()
            )

            caracteristica_inactiva = (
                Caracteristica.objects.filter(
                    producto=instance,
                    nombre=c_nombre,
                    activo=False
                ).first()
            )
            
            if caracteristica:
                caracteristica.nombre = c_nombre
                # caracteristica.activo = True
                caracteristica.save()
            
            elif(caracteristica_inactiva):
               caracteristica = caracteristica_inactiva
               caracteristica.activo = True
               caracteristica.save() 
            else:
                caracteristica = Caracteristica.objects.create(
                    producto = instance,
                    nombre = c_nombre
                )

                 
            caracteristicas_ids.append(caracteristica.id)
            opciones_ids = []

            # Actulizacion caracteristicas
            for o_data in opciones_data:
                
                habitaciones_ids = o_data.pop('habitaciones_recomendadas', [])
                o_id = o_data.get('id', None)

                if o_id:
                    opcion = caracteristica.opciones.get(id=o_id)
                    opcion.nombre = o_data.get('nombre', opcion.nombre)
                    opcion.precio_extra = o_data.get('precio_extra', opcion.precio_extra)
                    opcion.descripcion = o_data.get('descripcion', opcion.descripcion)
                    opcion.activo = True

                    opcion.save()
                else: 
                    opcion_existente = (
                        Opcion.objects.filter(
                            caracteristica=caracteristica,
                            nombre=o_data['nombre'],
                            # activo=False
                        ).first()
                    )

                    if opcion_existente:
                        opcion = opcion_existente
                        opcion.nombre = o_data.get('nombre', opcion.nombre)
                        opcion.precio_extra = o_data.get('precio_extra', opcion.precio_extra)
                        opcion.descripcion = o_data.get('descripcion', opcion.descripcion)
                        opcion.activo = True
                        opcion.save()
                    else: 
                        opcion = Opcion.objects.create(
                            caracteristica = caracteristica,
                            **o_data
                        )

                opciones_ids.append(opcion.id)

                Recomendacion.objects.filter(
                    opcion = opcion
                ).delete()
                
                for habitacion_id in habitaciones_ids:
                    Recomendacion.objects.create(
                        opcion=opcion,
                        habitacion_id=habitacion_id,
                        caracteristica=caracteristica
                    )

            opciones_desactivadas = caracteristica.opciones.exclude(id__in=opciones_ids)

            for opcion in opciones_desactivadas:
                opcion.activo = False
                opcion.save()
                
        caracteristicas_desactivadas = instance.caracteristicas.exclude(id__in=caracteristicas_ids)

        for caracteristica in caracteristicas_desactivadas:
            caracteristica.activo = False
            caracteristica.save()
        
        return instance

    @staticmethod
    def eliminar_producto(producto:Producto):
        # devuelve true si se desactivo y false si se elimino
        usado = LineaPresupuesto.objects.filter(producto = producto).exists()

        if usado:
            producto.activo = False
            producto.save()

            return True

        producto.delete()
        return False

