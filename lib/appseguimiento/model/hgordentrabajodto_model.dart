import 'dart:convert';

List<HgOrdenTrabajoDto> hgReporteFallaDtoFromJson(String str) {
  final dynamic jsonData = json.decode(str);

  if (jsonData is List) {
    return jsonData.map((x) => HgOrdenTrabajoDto.fromJson(x)).toList();
  } else if (jsonData is Map<String, dynamic>) {
    return [HgOrdenTrabajoDto.fromJson(jsonData)];
  } else {
    throw Exception("Formato de JSON no válido");
  }
}

String hgOrdenTrabajoDtoToJson(List<HgOrdenTrabajoDto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HgOrdenTrabajoDto {
  int? id;
  int? dfecha;
  int? dfechasal;
  String? idplacatracto;
  String? idplacaacople;
  int? nkilometraje;
  int? idvehiculoext;
  int? idacopleext;
  String? idcentrocosto;
  String? ccentrocosto;
  String? idcentrocosto1;
  String? ccentrocosto1;
  bool? bcerrada;
  int? nkilometrajegps;
  bool? bcerradaoperaciones;
  bool? bmseguimiento;
  int? idreportefalla;
  String? supervisor;
  String? taller;
  int? idtipounidad;
  double? nhorometro;
  bool? btercero;
  String? idtipoot;
  String? idpreventivo;
  String? idusureg;
  bool? bactivo;
  String? idusumod;
  int? dfecreg;
  int? dfecmod;
  String? cobservaciones;
  int? idnreportefalla;

  HgOrdenTrabajoDto({
    this.id,
    this.dfecha,
    this.dfechasal,
    this.idplacatracto,
    this.idplacaacople,
    this.nkilometraje,
    this.idvehiculoext,
    this.idacopleext,
    this.idcentrocosto,
    this.ccentrocosto,
    this.idcentrocosto1,
    this.ccentrocosto1,
    this.bcerrada,
    this.nkilometrajegps,
    this.bcerradaoperaciones,
    this.bmseguimiento,
    this.idreportefalla,
    this.supervisor,
    this.taller,
    this.idtipounidad,
    this.nhorometro,
    this.btercero,
    this.idtipoot,
    this.idpreventivo,
    this.idusureg,
    this.bactivo,
    this.idusumod,
    this.dfecreg,
    this.dfecmod,
    this.cobservaciones,
    this.idnreportefalla,
  });

  factory HgOrdenTrabajoDto.fromJson(Map<String, dynamic> json) =>
      HgOrdenTrabajoDto(
        id: json["id"],
        dfecha: json["dfecha"],
        dfechasal: json["dfechasal"],
        idplacatracto: json["idplacatracto"],
        idplacaacople: json["idplacaacople"],
        nkilometraje: json["nkilometraje"],
        idvehiculoext: json["idvehiculoext"],
        idacopleext: json["idacopleext"],
        idcentrocosto: json["idcentrocosto"],
        ccentrocosto: json["ccentrocosto"],
        idcentrocosto1: json["idcentrocosto1"],
        ccentrocosto1: json["ccentrocosto1"],
        bcerrada: json["bcerrada"],
        nkilometrajegps: json["nkilometrajegps"],
        bcerradaoperaciones: json["bcerradaoperaciones"],
        bmseguimiento: json["bmseguimiento"],
        idreportefalla: json["idreportefalla"],
        supervisor: json["supervisor"],
        taller: json["taller"],
        idtipounidad: json["idtipounidad"],
        nhorometro: json["nhorometro"],
        btercero: json["btercero"],
        idtipoot: json["idtipoot"],
        idpreventivo: json["idpreventivo"],
        idusureg: json["idusureg"],
        bactivo: json["bactivo"],
        idusumod: json["idusumod"],
        dfecreg: json["dfecreg"],
        dfecmod: json["dfecmod"],
        cobservaciones: json["cobservaciones"],
        idnreportefalla: json["idnreportefalla"],
      );

  get oc => null;

  Map<String, dynamic> toJson() => {
        "id": id,
        "dfecha": dfecha,
        "dfechasal": dfechasal,
        "idplacatracto": idplacatracto,
        "idplacaacople": idplacaacople,
        "nkilometraje": nkilometraje,
        "idvehiculoext": idvehiculoext,
        "idacopleext": idacopleext,
        "idcentrocosto": idcentrocosto,
        "ccentrocosto": ccentrocosto,
        "idcentrocosto1": idcentrocosto1,
        "ccentrocosto1": ccentrocosto1,
        "bcerrada": bcerrada,
        "nkilometrajegps": nkilometrajegps,
        "bcerradaoperaciones": bcerradaoperaciones,
        "bmseguimiento": bmseguimiento,
        "idreportefalla": idreportefalla,
        "supervisor": supervisor,
        "taller": taller,
        "idtipounidad": idtipounidad,
        "nhorometro": nhorometro,
        "btercero": btercero,
        "idtipoot": idtipoot,
        "idpreventivo": idpreventivo,
        "idusureg": idusureg,
        "bactivo": bactivo,
        "idusumod": idusumod,
        "dfecreg": dfecreg,
        "dfecmod": dfecmod,
        "cobservaciones": cobservaciones,
        "idnreportefalla": idnreportefalla,
      };
}
