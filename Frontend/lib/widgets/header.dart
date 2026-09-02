import 'package:aluminios/repository/user_repository.dart';
import 'package:flutter/material.dart';

class  Header extends StatelessWidget implements PreferredSizeWidget{
  final String name;
  final bool isLoged;
  const Header({super.key, required this.name, required this.isLoged});


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool esMovil = screenWidth < 700;
    return Container(
      padding: esMovil
          ? EdgeInsets.only( bottom: 20, left: 0, right: 10)
          : EdgeInsets.symmetric(horizontal:screenWidth*0.05),
      child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset('assets/imagenes/logo-color.png', height: esMovil ? 50 :100,),
                  SizedBox(width: esMovil ?  screenWidth*0.025 : screenWidth*0.05,),
                  Text(
                    'ALUMINIOS AYALA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: esMovil ? 20 : 24,
                      color: Color(0xFF222B6F),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (esMovil)...[
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Color(0xFF222B6F), size: 30),
                      onSelected: (val) {
                        switch (val) {
                          case 'login':
                            Navigator.pushNamed(context, 'login/');
                            break;
                          case 'register':
                            Navigator.pushNamed(context, 'register/');
                            break;
                          case 'edit_info':
                            Navigator.pushNamed(context, 'editInformation/');
                            break;
                          case 'logout':
                            UserRepository().logout();
                            Navigator.pushNamed(context, '/');
                            break;

                          case 'crear_presupuesto':
                            Navigator.pushNamed(context, 'createPresupuesto/');
                            break;
                          case 'listado_presupuestos':
                            Navigator.pushNamed(context, 'listadoPresupuestos/');
                            break;
                          case 'mis_proyectos':
                            Navigator.pushNamed(context, 'misProyectos/');
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isLoged) ...[
                          const PopupMenuItem(value: 'login', child: Text('Iniciar Sesión')),
                          const PopupMenuItem(value: 'register', child: Text('Crear cuenta')),
                        ] else ...[
                          const PopupMenuItem(value: 'edit_info', child: Text('Modificar Datos')),
                          const PopupMenuItem(value: 'logout', child: Text('Cerrar Sesión')),
                        ],

                        const PopupMenuDivider(),

                        const PopupMenuItem(value: 'crear_presupuesto', child: Text('Crear Presupuesto')),
                        const PopupMenuItem(value: 'listado_presupuestos', child: Text('Mis Presupuestos')),
                        const PopupMenuItem(value: 'mis_proyectos', child: Text('Mis Proyectos')),

                      ],
                    ),
                  ]else...[
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF222B6F),
                      ),
                    ),

                    PopupMenuButton<String>(
                        icon: Icon(Icons.perm_identity, color: Color(0xFF222B6F), size: 40, key: const Key("iconoPersona")),
                        onSelected: (val) {
                          switch(val){
                            case '1':
                              Navigator.pushNamed(context, 'login/');
                              break;
                            case '2':
                              Navigator.pushNamed(context, 'register/');
                              break;
                            case '3':
                              Navigator.pushNamed(context, 'editInformation/');
                              break;
                            case '4':
                              UserRepository().logout();
                              Navigator.pushNamed(context, '/');
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          if (!isLoged)...[
                            const PopupMenuItem(value: '1', key:  Key("inisesion"), child: Text('Iniciar Sesión'),),
                            const PopupMenuItem(value: '2', child: Text('Crear cuenta')),
                          ]
                          else ... [
                            const PopupMenuItem(value: '3', child: Text('Modificar Datos')),
                            const PopupMenuItem(value: '4', key: Key('cerrarSesion'), child: Text('Cerrar Sesión'), ),
                          ]
                        ]

                    ),
                      PopupMenuButton<String>(
                          icon: Icon(Icons.shopping_bag_outlined, color: Color(0xFF222B6F), size: 40,),
                          onSelected: (val) {
                            switch(val){
                              case '1':
                                Navigator.pushNamed(context, 'createPresupuesto/');
                                break;
                              case '2':
                                Navigator.pushNamed(context, 'listadoPresupuestos/');
                                break;

                              case '3':
                                Navigator.pushNamed(context, 'misProyectos/');
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: '1', key:  Key('crearPresupuesto'), child: Text('Crear Presupuesto')),
                            const PopupMenuItem(value: '2', key: Key('listadoPresupuesto'), child: Text('Mis Presupuestos')),
                            const PopupMenuItem(value: '3', key: Key('listadoProyectos'), child: Text('Mis Proyectos')),
                          ]
                      ),
                  ],
                ],
              ),
            ],
          )
      ),
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}