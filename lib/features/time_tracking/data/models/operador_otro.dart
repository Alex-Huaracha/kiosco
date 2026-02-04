import 'dart:convert';

List<HgOperadorOtroDto> hgOperadorOtroDtoFromJson(String str) =>
    List<HgOperadorOtroDto>.from(
        json.decode(str).map((x) => HgOperadorOtroDto.fromJson(x)));

String hgOperadorOtroDtoToJson(List<HgOperadorOtroDto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HgOperadorOtroDto {
  String? idempleado;
  String? nombres;
  String? apellidopaterno;
  String? apellidomaterno;
  String? numerodocumento;
  String? activo;
  String? idcargo;
  String? ccargo;
  String? idarea;
  String? carea;
  String? idcontrato;
  String? idcuenta;
  String? cuenta;
  String? fechaingreso;
  String? fechacese;

  HgOperadorOtroDto({
    this.idempleado,
    this.nombres,
    this.apellidopaterno,
    this.apellidomaterno,
    this.numerodocumento,
    this.activo,
    this.idcargo,
    this.ccargo,
    this.idarea,
    this.carea,
    this.idcontrato,
    this.idcuenta,
    this.cuenta,
    this.fechaingreso,
    this.fechacese,
  });

  factory HgOperadorOtroDto.fromJson(Map<String, dynamic> json) =>
      HgOperadorOtroDto(
        idempleado: json["idempleado"],
        nombres: json["nombres"],
        apellidopaterno: json["apellidopaterno"],
        apellidomaterno: json["apellidomaterno"],
        numerodocumento: json["numerodocumento"],
        activo: json["activo"],
        idcargo: json["idcargo"],
        ccargo: json["ccargo"],
        idarea: json["idarea"],
        carea: json["carea"],
        idcontrato: json["idcontrato"],
        idcuenta: json["idcuenta"],
        cuenta: json["cuenta"],
        fechaingreso: json["fechaingreso"],
        fechacese: json["fechacese"],
      );

  get oc => null;

  Map<String, dynamic> toJson() => {
        "idempleado": idempleado,
        "nombres": nombres,
        "apellidopaterno": apellidopaterno,
        "apellidomaterno": apellidomaterno,
        "numerodocumento": numerodocumento,
        "activo": activo,
        "idcargo": idcargo,
        "ccargo": ccargo,
        "idarea": idarea,
        "carea": carea,
        "idcontrato": idcontrato,
        "idcuenta": idcuenta,
        "cuenta": cuenta,
        "fechaingreso": fechaingreso,
        "fechacese": fechacese,
      };
}
