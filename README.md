# TFG- Sistema multiplataforma para la creación de presupuestos y gestión de un negocio

Aplicación multiplataforma desarrollada como Trabajo de Fin de Grado en Ingeniería Informática para la gestión de una empresa en el sector del Aluminio.

El objetivo principal del proyecto es digitalizar y automatizar diferentes procesos internos de la empresa, como es la creación y gestiń de presupuestos, la planofocación de tareas o la gestion de proyectos entre otros.

## Tecnologías utilizadas
* Bakend : Django.
* Frontend : Flutter con Dart
* Base de datos: PostegreSQL
* Servicios externos: Stripe, Gmail y Nominatim

La aplicación sigue una arquitectura CLiente-Servidor, saparada en diferentes capas (lógica de negocio, presentación y datos).

## Funciones principales
* Gestión de clientes y usuarios.
* Creación y gestión de presupuestos.
* Gestión del ciclo de vida de los proyectos.
* Gestión de productos.
* Creaciónde un sistemadeturnos para realizar reuniones cliente-negocio.
* Planificación automática de tareas.
* Integración de una pasarela de pago mediante Stripe.
* Restricciones en los métodos de entrega.

## Requisitos previos
Para poder ejecutar el proyecto en local es necesario tener:
* Python
* Flutter y Dart
* PostgreSQL
* Stripe CLI
* Una cuenta de correo para el envío de emails
* Un fichero .env configurado correctamente


## Configuración del entorno

El backend necesita un fichero .env situado en su directorio raíz. Por motivos de seguridad este fichoero no puede subirse al repositorio, ya que contiene claves secretas y credenciales.

El fichero .env debe contener los siguiente:

```
# Django
SECRET_KEY= <clave_secreta_de_django>
DEBUG=True

# Stripe
STRIPE_SECRET_KEY=<clave_secreta_de_stripe>
STRIPE_WEBHOOK_SECRET=<clave_secreta_del_webhook>
SUCCESS_URL=<url_de_pago_correcto>
CANCEL_URL=<url_de_pago_cancelado>

# Email
EMAIL_HOST_USER=<direccion_de_correo>
EMAIL_HOST_PASSWORD=<contraseña_o_clave_de_aplicacion>
DEFAULT_FROM_EMAIL=<direccion_desde_la_que_se_envian_los_correos>

# Coordenadas de la empresa
COORDENADAS_EMPRESA_LAT=<latitud>
COORDENADAS_EMPRESA_LON=<longitud>

``` 

## Inicialización del Backend:
1. Crear entono virtual:   ```python3 -m venv .venv```
2. Activar el entorno:     ```source .venv/bin/activate```
3. Aplicar migraciones:     ```python manage.py migrate```
4. Creación de recursos:    ```python manage.py init_bd```
5. Ejecutar servidor:       ```python manage.py runserver```


## Inicialización de Flutter:
1. Obtener dependencias: ```flutter pub get```
2. Ejecutar la aplicación: ```flutter run -d chrome --web-port=46115```

## Configuración de Stripe:
Durante el dedsarrollo y las pruebas es necesario usar Stripe CLI para recibir los eventos enviados por Stripe y redigirlos al endpoint correspondiente del backend para ello es usa el comando:

```stripe listen --forward-to http://127.0.0.1:8000/api/proyectos/stripe_webhook```


## Test
* Test unitarios realizados sobre el backend se usa: ``` python manage.py test```
* Las pruebas de widgets realizadas sobre flutter se usa: ```flutter test```
* Los test de sistema, para lanzarlos tenemos que seguir los sigientes pasos:
    1. En el servidor debemos generar los recursos conocidos por los test: ``` python manage.py test_data```
    2. Lanzar servidor : ```python manage.py runserver```
    3. En el frontend : ```flutter test -d linux integration_test/test_sistema.dart```



 
