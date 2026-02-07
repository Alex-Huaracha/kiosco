import 'dart:convert';

/// Parser para lista de empleados desde JSON
List<HgEmpleadoMantenimientoDto> hgEmpleadoMantenimientoDtoFromJson(String str) {
  final List<dynamic> decoded = json.decode(str);
  return List<HgEmpleadoMantenimientoDto>.from(
    decoded.map((x) => HgEmpleadoMantenimientoDto.fromJson(x))
  );
}

/// Serializer para lista de empleados a JSON
String hgEmpleadoMantenimientoDtoToJson(List<HgEmpleadoMantenimientoDto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

/// DTO para empleados de mantenimiento.
/// Representa un tecnico que puede tener actividades asignadas.
class HgEmpleadoMantenimientoDto {
  int? id;
  String? nombres;
  String? apellidopaterno;
  String? apellidomaterno;
  String? numerodocumento;
  String? cargo;
  String? area;
  int? idarea;
  String? fechanacimiento;
  String? sexo;
  int? activo;
  
  /// Cantidad de Tareas Principales (TP) no backlog
  int? cantidadActividades;
  
  /// Cantidad de Tareas Principales en backlog
  int? cantidadBacklog;
  
  /// Cantidad de Sub-Tareas (ST) donde el empleado es asistente
  int? cantidadAsistencias;
  
  /// Total de todas las actividades (TP + ST + Backlog)
  int? cantidadTotal;

  HgEmpleadoMantenimientoDto({
    this.id,
    this.nombres,
    this.apellidopaterno,
    this.apellidomaterno,
    this.numerodocumento,
    this.cargo,
    this.area,
    this.idarea,
    this.fechanacimiento,
    this.sexo,
    this.activo,
    this.cantidadActividades,
    this.cantidadBacklog,
    this.cantidadAsistencias,
    this.cantidadTotal,
  });

  factory HgEmpleadoMantenimientoDto.fromJson(Map<String, dynamic> json) =>
      HgEmpleadoMantenimientoDto(
        id: json["id"],
        nombres: json["nombres"],
        apellidopaterno: json["apellidopaterno"],
        apellidomaterno: json["apellidomaterno"],
        numerodocumento: json["numerodocumento"],
        cargo: json["cargo"],
        area: json["area"],
        idarea: json["idarea"],
        fechanacimiento: json["fechanacimiento"],
        sexo: json["sexo"],
        activo: json["activo"],
        cantidadActividades: json["cantidadActividades"],
        cantidadBacklog: json["cantidadBacklog"],
        cantidadAsistencias: json["cantidadAsistencias"],
        cantidadTotal: json["cantidadTotal"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "nombres": nombres,
        "apellidopaterno": apellidopaterno,
        "apellidomaterno": apellidomaterno,
        "numerodocumento": numerodocumento,
        "cargo": cargo,
        "area": area,
        "idarea": idarea,
        "fechanacimiento": fechanacimiento,
        "sexo": sexo,
        "activo": activo,
        "cantidadActividades": cantidadActividades,
        "cantidadBacklog": cantidadBacklog,
        "cantidadAsistencias": cantidadAsistencias,
        "cantidadTotal": cantidadTotal,
      };

  /// Nombre completo formateado: "NOMBRES APELLIDOPATERNO APELLIDOMATERNO"
  String get nombreCompleto {
    String nombre = nombres ?? '';
    String paterno = apellidopaterno ?? '';
    String materno = apellidomaterno ?? '';
    return '$nombre $paterno $materno'.trim();
  }

  /// Iniciales (primera letra del nombre y apellido paterno)
  String get iniciales {
    String primera = (nombres != null && nombres!.isNotEmpty) ? nombres![0] : '';
    String segunda = (apellidopaterno != null && apellidopaterno!.isNotEmpty) 
        ? apellidopaterno![0] : '';
    return '$primera$segunda'.toUpperCase();
  }
}
