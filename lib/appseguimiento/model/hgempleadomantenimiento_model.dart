import 'dart:convert';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';

// Modelo wrapper para la respuesta del servidor
class HgEmpleadoMantenimientoResponse {
  int? rest;
  List<HgEmpleadoMantenimientoDto>? empleado;

  HgEmpleadoMantenimientoResponse({
    this.rest,
    this.empleado,
  });

  factory HgEmpleadoMantenimientoResponse.fromJson(Map<String, dynamic> json) =>
      HgEmpleadoMantenimientoResponse(
        rest: json["rest"],
        empleado: json["empleado"] == null
            ? []
            : List<HgEmpleadoMantenimientoDto>.from(
                json["empleado"].map((x) => HgEmpleadoMantenimientoDto.fromJson(x))),
      );
}

List<HgEmpleadoMantenimientoDto> hgEmpleadoMantenimientoDtoFromJson(String str) {
  final Map<String, dynamic> jsonMap = json.decode(str);
  final response = HgEmpleadoMantenimientoResponse.fromJson(jsonMap);
  return response.empleado ?? [];
}

String hgEmpleadoMantenimientoDtoToJson(List<HgEmpleadoMantenimientoDto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

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
      };

  // Método para obtener el nombre completo formateado
  String get nombreCompleto {
    String nombre = nombres ?? '';
    String paterno = apellidopaterno ?? '';
    String materno = apellidomaterno ?? '';
    return '$nombre $paterno $materno'.trim();
  }

  // Método para obtener las iniciales (primera letra del nombre y apellido paterno)
  String get iniciales {
    String primera = (nombres != null && nombres!.isNotEmpty) ? nombres![0] : '';
    String segunda = (apellidopaterno != null && apellidopaterno!.isNotEmpty) 
        ? apellidopaterno![0] : '';
    return '$primera$segunda'.toUpperCase();
  }

  // Método de conversión a HgOperadorOtroDto para compatibilidad con el sistema actual
  HgOperadorOtroDto toOperadorOtroDto() {
    return HgOperadorOtroDto(
      idempleado: id?.toString(),
      nombres: nombres,
      apellidopaterno: apellidopaterno,
      apellidomaterno: apellidomaterno,
      numerodocumento: numerodocumento,
      ccargo: cargo,
      carea: area,
      idarea: idarea?.toString(),
      activo: activo?.toString(),
      cuenta: numerodocumento, // Usamos el DNI como cuenta
      idcargo: null,
      idcontrato: null,
      idcuenta: null,
      fechaingreso: null,
      fechacese: null,
    );
  }
}
