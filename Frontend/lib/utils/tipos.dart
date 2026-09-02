import 'package:flutter/material.dart';
enum PageKind {
  mistareas,
  todastareas,
  usuarios,
  crearUsuario,
  productos,
  mispresupuestos,
  modificardatos,
  crearpreuspuesto,
  proyectos,
  crearProducto,
  modificarProducto,
  confirmacionPresupuesto,
  misproyectos,
  gestioncitas,
  modificarProyecto,
  verProyecto,
  configuracion,
  modificarOtrosUsuarios,

}
enum UserType {jefe, administrativo, trabajador, cliente, todos}

enum HabitacionType { dormitorio, banio, resto, ninguna}

enum EstadoProyecto {
  todo('Todos', Color(0xFF222B6F)),
  pendiente_pago('Pendiente de Pago', Color(0xFFE67E22)),
  pendiente_cita('Pendiente cita',Color(0xFF3498DB)),
  revision('En Revisión', Color(0xFF9B59B6)),
  materiales('Pidiendo Materiales', Color(0xFFF1C40F)),
  esperando_materiales('Esperando Materiales', Color(0xFFE67E22)),
  produccion('En Producción', Color(0xFF1ABC9C)),
  listo_envio('Preparando para enviarse', Color(0xFFFF7EBF)),
  listo_recogida('Listo para recoger',Color(0xFF27AE60)),
  listo_montaje('Listo para montar',  Color(0xFF2980B9)),
  enviado ('El pedido ha sido enviado', Color(0xFF27AE60)),
  montaje('Listo para montar', Color(0xFF27AE60)),
  finalizado('Finalizado', Color(0xFF222B6F)),
  cancelado('Cancelado', Color(0xFFE74C3C));

  final String text;
  final Color color;

  const EstadoProyecto(this.text, this.color);
}

enum EstadoCita{
  disponible ('Disponible'),
  reservada ('Reservada'),
  completada ('Completada'),
  cancelada ('Cancelada');

  final String text;
  const EstadoCita(this.text);
}

enum TipoTarea {
  cortar ('Cortar'),
  mecanizar('Mecanizar'),
  montar ('Montar'),
  ensamblar('Ensamblar'),
  montaje('Montar proyecto'),
  preparar_envio("Preparar envío");

  final String text;
  const TipoTarea(this.text);
}