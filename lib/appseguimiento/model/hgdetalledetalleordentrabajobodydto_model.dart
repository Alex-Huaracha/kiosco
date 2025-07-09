import 'dart:convert';

String hgDetalleOrdenTrabajoBodyDtoToJson(
        List<HgDetalleOrdenTrabajoBodyDto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HgDetalleOrdenTrabajoBodyDto {
  String? idordentrabajo;
  String? iddetalleordentrabajo;
  String? idempleadoext;
  String? ccargoemp;
  String? cnombreemp;
  String? dtiempoinicio;
  String? dtiempofin;

  HgDetalleOrdenTrabajoBodyDto({
    this.idordentrabajo,
    this.iddetalleordentrabajo,
    this.idempleadoext,
    this.ccargoemp,
    this.cnombreemp,
    this.dtiempoinicio,
    this.dtiempofin,
  });

  factory HgDetalleOrdenTrabajoBodyDto.fromJson(Map<String, dynamic> json) =>
      HgDetalleOrdenTrabajoBodyDto(
        idordentrabajo: json["idordentrabajo"],
        iddetalleordentrabajo: json["iddetalleordentrabajo"],
        idempleadoext: json["idempleadoext"],
        ccargoemp: json["ccargoemp"],
        cnombreemp: json["cnombreemp"],
        dtiempoinicio: json["dtiempoinicio"],
        dtiempofin: json["dtiempofin"],
      );

  get oc => null;

  Map<String, dynamic> toJson() => {
        "idordentrabajo": idordentrabajo,
        "iddetalleordentrabajo": iddetalleordentrabajo,
        "idempleadoext": idempleadoext,
        "ccargoemp": ccargoemp,
        "cnombreemp": cnombreemp,
        "dtiempoinicio": dtiempoinicio,
        "dtiempofin": dtiempofin,
      };
}
