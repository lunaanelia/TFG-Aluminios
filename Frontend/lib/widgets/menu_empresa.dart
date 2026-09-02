import 'package:aluminios/repository/user_repository.dart';
import 'package:flutter/material.dart';
import '../utils/tipos.dart';

class MenuEmpresa extends StatelessWidget{
  final PageKind current;
  final UserType rol;

  const MenuEmpresa({super.key, required this.current, required this.rol});

  @override
  Widget build(BuildContext context) {
    return Drawer(
     child: Column(
       children: [
         Container(width: double.infinity,
           padding: const EdgeInsets.only(top: 40, left: 20, right: 10, bottom: 20),
           decoration: const BoxDecoration(
             color: Color(0xFF222B6F),
           ),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text(
                 'Menú',
                 style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
               ),

               IconButton(
                 icon: const Icon(Icons.close, color: Colors.white,),
                 onPressed: () {
                   Navigator.pop(context);
                 },
               ),
             ],
           ),),
         Expanded(child: ListView(
           padding: EdgeInsets.zero,
           children: [
             if(rol != UserType.administrativo)...[
               ListTile(
                 key: const Key('tareas'),
                 title: const Text('Mis tareas'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.mistareas,
                 onTap: current == PageKind.mistareas ? null : () {
                     Navigator.pushNamed(context, 'misTareas/');
                 },
               ),
             ],

             if(rol == UserType.jefe) ...[
               ListTile(
                 title: const Text('Todas las tareas'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.todastareas,
                 onTap: current == PageKind.todastareas ? null : () {
                   Navigator.pushNamed(context, 'todasTareas/');
                 },
               ),
             ],

             if(rol == UserType.jefe || rol == UserType.administrativo) ...[
               const Divider(),
               ListTile(
                 key: const Key('proyectos'),
                 title: const Text('Proyectos'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.proyectos,
                 onTap: current == PageKind.proyectos ? null : () {
                   Navigator.pushNamed(context, 'listadoProyectos/');
                 },
               ),
               const Divider(),
               ListTile(
                 title: const Text('Productos'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.productos,
                 onTap: current == PageKind.productos ? null : () {
                   Navigator.pushNamed(context, 'gestionProductos/');
                 },
               ),
               ListTile(
                 title: const Text('Crear producto'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.crearProducto,
                 onTap: current == PageKind.crearProducto ? null : () {
                   Navigator.pushNamed(context, 'createProduct/');

                 },
               ),
             ],

             if(rol == UserType.jefe ) ...[
               const Divider(),
               ListTile(
                 title: const Text('Usuarios'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.usuarios,
                 onTap: current == PageKind.usuarios ? null : () {
                   Navigator.pushNamed(context, 'gestionUsers/');
                 },
               ),

               ListTile(
                 title: const Text('Crear usuario'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.crearUsuario,
                 onTap: current == PageKind.crearUsuario ? null : () {
                   Navigator.pushNamed(context, 'createUser/');
                 },
               ),

               ListTile(
                  key: const Key('gestionCitas'),
                 title: const Text('Gestión de citas'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.gestioncitas,
                 onTap: current == PageKind.gestioncitas ? null : () {
                   Navigator.pushNamed(context, 'crearCita/');
                 },
               ),

             ],
             const Divider(),
             ListTile(
               title: const Text('Mis presupuestos'),
               selectedColor: const Color(0xFF222B6F),
               selected: current == PageKind.mispresupuestos,
               onTap: current == PageKind.mispresupuestos ? null : () {
                 Navigator.pushNamed(context, 'listadoPresupuestos/');
               },
             ),
             ListTile(
               title: const Text('Crear presupuesto'),
               selectedColor: const Color(0xFF222B6F),
               selected: current == PageKind.crearpreuspuesto,
               onTap: current == PageKind.crearpreuspuesto ? null : () {
                 Navigator.pushNamed(context, 'createPresupuesto/');
               },
             ),
             ListTile(
               title: const Text('Mis proyectos'),
               selectedColor: const Color(0xFF222B6F),
               selected: current == PageKind.misproyectos,
               onTap: current == PageKind.misproyectos ? null : () {
                 Navigator.pushNamed(context, 'misProyectos/');
               },
             ),
             const Divider(),
             ListTile(
               title: const Text(
                   'Modificar datos',
               ),
               selectedColor: const Color(0xFF222B6F),
               selected: current == PageKind.modificardatos,
               onTap: current == PageKind.modificardatos ? null : () {
                 Navigator.pushNamed(context, 'editInformation/');
               },
             ),

             if(rol == UserType.jefe)...[
               ListTile(
                 title: const Text('Configuracion'),
                 selectedColor: const Color(0xFF222B6F),
                 selected: current == PageKind.configuracion,
                 onTap: current == PageKind.configuracion ? null : () {
                   Navigator.pushNamed(context, 'configuracion/');
                 },
               ),
             ],
             ListTile(
               key: const Key('cerrarSesion'),
               title: const Text('Cerrar sesión'),
               onTap: () {
                  UserRepository().logout();
                  Navigator.pushNamed(context, '/');
               },
             ),
           ],
         )),
       ],
     ),
    );
  }
}