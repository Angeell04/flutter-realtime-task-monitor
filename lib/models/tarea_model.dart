import 'dart:convert';

Map<String, Tarea> tareasFromJson(String str) {
  final decoded = json.decode(str);
  if (decoded == null) return {};
  return Map<String, dynamic>.from(decoded as Map).map(
    (key, value) => MapEntry<String, Tarea>(
      key,
      Tarea.fromJson(Map<String, dynamic>.from(value as Map), id: key),
    ),
  );
}

String tareasToJson(Map<String, Tarea> data) => json.encode(
      Map.from(data).map(
        (key, value) => MapEntry<String, dynamic>(key, (value as Tarea).toJson()),
      ),
    );

List<Tarea> tareasListFromJson(String str) {
  final List<Tarea> lista = tareasFromJson(str).values.toList();

  lista.sort((a, b) {
    if (a.timestamp > 0 && b.timestamp > 0) {
      return b.timestamp.compareTo(a.timestamp);
    }
    if (a.id != null && b.id != null) {
      return b.id!.compareTo(a.id!);
    }
    return 0;
  });

  return lista;
}

class Tarea {
  final String? id;
  final String detallesErrores;
  final String duracion;
  final String estado;
  final String resumen;
  final String titulo;
  final String fecha;
  final int timestamp;

  Tarea({
    this.id,
    required this.detallesErrores,
    required this.duracion,
    required this.estado,
    required this.resumen,
    required this.titulo,
    this.fecha = '',
    this.timestamp = 0,
  });

  factory Tarea.fromJson(Map<String, dynamic> json, {String? id}) => Tarea(
        id: id,
        detallesErrores: json["detallesErrores"] ?? "",
        duracion: json["duracion"] ?? "",
        estado: json["estado"] ?? "",
        resumen: json["resumen"] ?? "",
        titulo: json["titulo"] ?? "",
        fecha: json["fecha"] ?? "",
        timestamp: (json["timestamp"] is int)
            ? json["timestamp"]
            : int.tryParse(json["timestamp"]?.toString() ?? "0") ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "detallesErrores": detallesErrores,
        "duracion": duracion,
        "estado": estado,
        "resumen": resumen,
        "titulo": titulo,
        "fecha": fecha,
        "timestamp": timestamp,
      };
}
