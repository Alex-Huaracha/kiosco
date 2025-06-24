import 'dart:convert';

List<HgOperadorDto> hgOperadorDtoFromJson(String str) =>
    List<HgOperadorDto>.from(
        json.decode(str).map((x) => HgOperadorDto.fromJson(x)));

String hgOperadorDtoToJson(List<HgOperadorDto> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class HgOperadorDto {
  String? idmanifiesto;
  String? fechamanifiesto;
  String? idcuenta;
  String? cuenta;
  String? idcuentaservicio;
  String? cuentaservicio;
  String? ruta;
  String? idtiposervicio;
  String? tiposervicio;
  String? estado;
  String? cestado;
  String? tracto;
  String? carroceriatracto;
  String? tractomarca;
  String? tractomodelo;
  String? carretamarca;
  String? carretamodelo;
  String? acople;
  String? carroceriaacople;
  String? guiatransportista;
  String? descripcion;
  String? usuario;
  String? nombreusuario;
  String? empresa;
  String? nombres;
  String? apellidos;
  String? cargo;
  String? numerodocumento;
  String? pesok;
  String? bultos;
  String? centercode;

  HgOperadorDto(
      {this.idmanifiesto,
      this.fechamanifiesto,
      this.idcuenta,
      this.cuenta,
      this.idcuentaservicio,
      this.cuentaservicio,
      this.ruta,
      this.idtiposervicio,
      this.tiposervicio,
      this.estado,
      this.cestado,
      this.tracto,
      this.carroceriatracto,
      this.tractomarca,
      this.tractomodelo,
      this.carretamarca,
      this.carretamodelo,
      this.acople,
      this.carroceriaacople,
      this.guiatransportista,
      this.descripcion,
      this.usuario,
      this.nombreusuario,
      this.empresa,
      this.nombres,
      this.apellidos,
      this.cargo,
      this.numerodocumento,
      this.pesok,
      this.bultos,
      this.centercode});

  factory HgOperadorDto.fromJson(Map<String, dynamic> json) => HgOperadorDto(
        idmanifiesto: json["idmanifiesto"],
        fechamanifiesto: json["fechamanifiesto"],
        idcuenta: json["idcuenta"],
        cuenta: json["cuenta"],
        idcuentaservicio: json["idcuentaservicio"],
        cuentaservicio: json["cuentaservicio"],
        ruta: json["ruta"],
        idtiposervicio: json["idtiposervicio"],
        tiposervicio: json["tiposervicio"],
        estado: json["estado"],
        cestado: json["cestado"],
        tracto: json["tracto"],
        carroceriatracto: json["carroceriatracto"],
        tractomarca: json["tractomarca"],
        tractomodelo: json["tractomodelo"],
        carretamarca: json["carretamarca"],
        carretamodelo: json["carretamodelo"],
        acople: json["acople"],
        carroceriaacople: json["carroceriaacople"],
        guiatransportista: json["guiatransportista"],
        descripcion: json["descripcion"],
        usuario: json["usuario"],
        nombreusuario: json["nombreusuario"],
        empresa: json["empresa"],
        nombres: json["nombres"],
        apellidos: json["apellidos"],
        cargo: json["cargo"],
        numerodocumento: json["numerodocumento"],
        pesok: json["pesok"],
        bultos: json["bultos"],
        centercode: json["centercode"],
      );

  get oc => null;

  Map<String, dynamic> toJson() => {
        "idmanifiesto": idmanifiesto,
        "fechamanifiesto": fechamanifiesto,
        "idcuenta": idcuenta,
        "cuenta": cuenta,
        "idcuentaservicio": idcuentaservicio,
        "cuentaservicio": cuentaservicio,
        "ruta": ruta,
        "idtiposervicio": idtiposervicio,
        "tiposervicio": tiposervicio,
        "estado": estado,
        "cestado": cestado,
        "idempleado": tracto,
        "carroceriatracto": carroceriatracto,
        "tractomarca": tractomarca,
        "tractomodelo": tractomodelo,
        "carretamarca": carretamarca,
        "carretamodelo": carretamodelo,
        "acople": acople,
        "carroceriaacople": carroceriaacople,
        "guiatransportista": guiatransportista,
        "descripcion": descripcion,
        "usuario": usuario,
        "nombreusuario": nombreusuario,
        "empresa": empresa,
        "nombres": nombres,
        "apellidos": apellidos,
        "cargo": cargo,
        "numerodocumento": numerodocumento,
        "pesok": pesok,
        "bultos": bultos,
        "centercode": centercode,
      };
}
