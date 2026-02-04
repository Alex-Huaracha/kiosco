import 'dart:convert';

List<HgDetalleOrdenTrabajoDto> hgDetalleOrdenTrabajoDtoFromJson(String str) =>
    List<HgDetalleOrdenTrabajoDto>.from(
        json.decode(str).map((x) => HgDetalleOrdenTrabajoDto.fromJson(x)));

String hgDetalleOrdenTrabajoDtoToJson(List<HgDetalleOrdenTrabajoDto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HgDetalleOrdenTrabajoDto {
  int? id;
  int? dfecreg;
  int? dfecmod;
  String? idusureg;
  String? idusumod;
  bool? bactivo;
  String? idfalla;
  String? idarticulosap;
  String? carticulosap;
  double? ncantidadart;
  String? idempleadoext;
  int? nminutosemp;
  int? ncantidadserv;
  bool? cestado;
  int? dfechacierre;
  int? idtipodet;
  String? cunimedsap;
  int? idactividad;
  String? cactividad;
  bool? bcerrada;
  bool? bbacklog;
  bool? bdescuento;
  bool? breprogramado;
  String? cobservaciones;
  String? ccargoemp;
  String? cnombreemp;
  int? dtiempoinicio;
  int? dtiempofin;
  int? iddetalleorigen;
  bool? bfallareportada;
  int? idsistema;
  int? idsubsistema;
  String? csistema;
  String? csubsistema;
  int? idordentrabajo;
  int? idservicio;
  bool? bbacklogrq;

  HgDetalleOrdenTrabajoDto({
    this.id,
    this.dfecreg,
    this.dfecmod,
    this.idusureg,
    this.idusumod,
    this.bactivo,
    this.idfalla,
    this.idarticulosap,
    this.carticulosap,
    this.ncantidadart,
    this.idempleadoext,
    this.nminutosemp,
    this.ncantidadserv,
    this.cestado,
    this.dfechacierre,
    this.idtipodet,
    this.cunimedsap,
    this.idactividad,
    this.cactividad,
    this.bcerrada,
    this.bbacklog,
    this.bdescuento,
    this.breprogramado,
    this.cobservaciones,
    this.ccargoemp,
    this.cnombreemp,
    this.dtiempoinicio,
    this.dtiempofin,
    this.iddetalleorigen,
    this.bfallareportada,
    this.idsistema,
    this.idsubsistema,
    this.csistema,
    this.csubsistema,
    this.idordentrabajo,
    this.idservicio,
    this.bbacklogrq,
  });
  factory HgDetalleOrdenTrabajoDto.fromJson(Map<String, dynamic> json) =>
      HgDetalleOrdenTrabajoDto(
        id: json["id"],
        dfecreg: json["dfecreg"],
        dfecmod: json["dfecmod"],
        idusureg: json["idusureg"],
        idusumod: json["idusumod"],
        bactivo: json["bactivo"],
        idfalla: json["idfalla"],
        idarticulosap: json["idarticulosap"],
        carticulosap: json["carticulosap"],
        ncantidadart: json["ncantidadart"],
        idempleadoext: json["idempleadoext"],
        nminutosemp: json["nminutosemp"],
        ncantidadserv: json["ncantidadserv"],
        cestado: json["cestado"],
        dfechacierre: json["dfechacierre"],
        idtipodet: json["idtipodet"],
        cunimedsap: json["cunimedsap"],
        idactividad: json["idactividad"],
        cactividad: json["cactividad"],
        bcerrada: json["bcerrada"],
        bbacklog: json["bbacklog"],
        bdescuento: json["bdescuento"],
        breprogramado: json["breprogramado"],
        cobservaciones: json["cobservaciones"],
        ccargoemp: json["ccargoemp"],
        cnombreemp: json["cnombreemp"],
        dtiempoinicio: json["dtiempoinicio"],
        dtiempofin: json["dtiempofin"],
        iddetalleorigen: json["iddetalleorigen"],
        bfallareportada: json["bfallareportada"],
        idsistema: json["idsistema"],
        idsubsistema: json["idsubsistema"],
        csistema: json["csistema"],
        csubsistema: json["csubsistema"],
        idordentrabajo: json["idordentrabajo"],
        idservicio: json["idservicio"],
        bbacklogrq: json["bbacklogrq"],
      );
  get oc => null;

  Map<String, dynamic> toJson() => {
        "id": id,
        "dfecreg": dfecreg,
        "dfecmod": dfecmod,
        "idusureg": idusureg,
        "idusumod": idusumod,
        "bactivo": bactivo,
        "idfalla": idfalla,
        "idarticulosap": idarticulosap,
        "carticulosap": carticulosap,
        "ncantidadart": ncantidadart,
        "idempleadoext": idempleadoext,
        "nminutosemp": nminutosemp,
        "ncantidadserv": ncantidadserv,
        "cestado": cestado,
        "dfechacierre": dfechacierre,
        "idtipodet": idtipodet,
        "cunimedsap": cunimedsap,
        "idactividad": idactividad,
        "cactividad": cactividad,
        "bcerrada": bcerrada,
        "bbacklog": bbacklog,
        "bdescuento": bdescuento,
        "breprogramado": breprogramado,
        "cobservaciones": cobservaciones,
        "ccargoemp": ccargoemp,
        "cnombreemp": cnombreemp,
        "dtiempoinicio": dtiempoinicio,
        "dtiempofin": dtiempofin,
        "iddetalleorigen": iddetalleorigen,
        "bfallareportada": bfallareportada,
        "idsistema": idsistema,
        "idsubsistema": idsubsistema,
        "csistema": csistema,
        "csubsistema": csubsistema,
        "idordentrabajo": idordentrabajo,
        "idservicio": idservicio,
        "bbacklogrq": bbacklogrq,
      };
}
