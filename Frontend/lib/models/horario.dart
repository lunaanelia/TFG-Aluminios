import 'package:flutter/material.dart';

class Turno {
  TimeOfDay inicio;
  TimeOfDay fin;
  Turno({required this.inicio, required this.fin});

  bool esIgualA(Turno otro) {
    return inicio.hour == otro.inicio.hour &&
        inicio.minute == otro.inicio.minute &&
        fin.hour == otro.fin.hour &&
        fin.minute == otro.fin.minute;
  }

  Turno copy() => Turno(inicio: inicio, fin: fin);

  Map<String, dynamic> toJson() => {
    'inicio': '${inicio.hour}:${inicio.minute.toString().padLeft(2, '0')}',
    'fin': '${fin.hour}:${fin.minute.toString().padLeft(2, '0')}',
  };

  factory Turno.fromJson(Map<String, dynamic> json) {
    dynamic inicioRaw = json['inicio'];
    dynamic finRaw = json['fin'];

    List<String> ini;
    List<String> f;

    if (inicioRaw is String) {
      ini = inicioRaw.split(':');
    } else if (inicioRaw is List) {
      ini = inicioRaw.map((e) => e.toString()).toList();
    } else {
      ini = ['0', '0'];
    }

    if (finRaw is String) {
      f = finRaw.split(':');
    } else if (finRaw is List) {
      f = finRaw.map((e) => e.toString()).toList();
    } else {
      f = ['0', '0'];
    }

    return Turno(
      inicio: TimeOfDay(
        hour: int.parse(ini[0]),
        minute: int.parse(ini[1]),
      ),
      fin: TimeOfDay(
        hour: int.parse(f[0]),
        minute: int.parse(f[1]),
      ),
    );
  }

}

class DiaLaboral {
  String nombre;
  List<Turno> turnos;

  DiaLaboral({required this.nombre, required this.turnos});

  DiaLaboral copy() {
    return DiaLaboral(
      nombre: nombre,
      turnos: turnos.map((t) => t.copy()).toList(),
    );
  }

  bool esIgualA(DiaLaboral otro) {
    if (nombre != otro.nombre) return false;
    if (turnos.length != otro.turnos.length) return false;

    for (int i = 0; i < turnos.length; i++) {
      if (!turnos[i].esIgualA(otro.turnos[i])) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'dia': nombre,
    'turnos': turnos.map((t)=> t.toJson()).toList(),
  };

  factory DiaLaboral.fromJson(Map<String, dynamic> json) {

    return DiaLaboral(
      nombre: json['dia'] ?? '',
      turnos: json['turnos'] != null
          ? (json['turnos'] as List).map((t) => Turno.fromJson(t)).toList()
          : [],);
  }

}