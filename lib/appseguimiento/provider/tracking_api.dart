import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalledetalleordentrabajobodydto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalleordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgresponseordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgempleadomantenimiento_model.dart';
import 'package:http/http.dart' as http;
import 'package:hgtrack/appseguimiento/model/hgoperadordto_model.dart';

class TrackingApi {
  static const String _hgapiEndpoint = kReleaseMode
      ? "https://extranetservicio.hagemsa.org/api/services"
      : "http://localhost:8080/hgapi";

  Future<List<HgOperadorDto>?> getAllTrackingOperador(String dni) async {
    var client = http.Client();
    var url = 'http://hagemsa.com/servicios/fuenteextranet.php?p=manifiestoresumen';

    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "idmanifiesto": null,
      "fechamanifiesto": null,
      "cuenta": null,
      "cuentaservicio": null,
      "tiposervicio": null,
      "tracto": null,
      "acople": null,
      "guiatransportista": null,
      "descripcion": null,
      "cseriesapgt": null,
      "cnumerosapgt": null,
      "cestado": null,
      "usuario": null,
      "nombreusuario": null,
      "empresa": null,
      "ruta": null,
      "cargo": null,
      "nombres": null,
      "numerodocumento": dni,
      "carroceriaacople": null,
      "carroceriatracto": null,
      "apellidos": null,
      "tractomarca": null,
      "tractomodelo": null,
      "carretamarca": null,
      "carretamodelo": null,
      "idcuenta": null,
      "idcuentaservicio": null,
      "idtiposervicio": null,
      "idguiasapgt": null,
      "estado": null,
      "bultos": null,
      "pesok": null,
      "centercode": null,
      "blistacompleta": null,
      "listanoid": null,
      "listaid": null,
      "listaidsmanifiesto": null,
      "idcentrocostos": null,
      "idempleado": null,
      "idplacatracto": null,
    });

    try {
      var response = await client.post(
        uri,
        headers: {
          //"Content-Type": "application/json",
        },
        body: jsonBody,
      );      
      if (response.statusCode == 200) {
        //print("Respuesta: ${response.body}");
        if (response.body == "[]") {
          return null;
        } else {
          return hgOperadorDtoFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción atrapada: $e");
    }
    return null;
  }

  Future<List<HgOperadorOtroDto>?> getAllTrackingOperadorOtro(
      String dni) async {
    var client = http.Client();
    var url = 'http://hagemsa.com/servicios/fuenteextranet.php?p=empleado';

    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({
      "idempleado": null,
      "nombres": null,
      "apellidopaterno": null,
      "apellidomaterno": null,
      "numerodocumento": dni,
      "fechaingreso": null,
      "fechacese": null,
      "ccargo": null,
      "carea": null,
      "activo": null,
      "idcargo": null,
      "idarea": null,
      "idcontrato": null,
      "blistacompleta": null,
      "nminutostotal": null
    });

    try {
      var response = await client.post(
        uri,
        headers: {
          //"Content-Type": "application/json",
        },
        body: jsonBody,
      );      
      if (response.statusCode == 200) {
        //print("Respuesta: ${response.body}");
        if (response.body == "[]") {
          return null;
        } else {
          return hgOperadorOtroDtoFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción atrapada: $e");
    }
    return null;
  }

  Future<List<HgResponseOrdenTrabajoDto>?> getAllTrackingOrdenTrabajo(
      String id,
      String dfecha,
      String idplacatracto,
      String bactivo,
      String idcentrocosto,
      String ccentrocosto,
      String supervisor,
      String taller) async {
    var clientrf = http.Client();
    var url_ot = '$_hgapiEndpoint/consultarordentrabajo';
    var uri_ot = Uri.parse(url_ot);

    String jsonBody = jsonEncode({
      "id": null,
      "dfecha": null,
      "idplacatracto": null,
      "bactivo": null,
      "idcentrocosto": null,
      "ccentrocosto": null,
      "supervisor": null,
      "taller": null,
    });

    try {
      var response = await clientrf.post(
        uri_ot,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        //print("Respuesta: ${response.body}");
        if (response.body == "[]") {
          return null;
        } else {
          return hgResponseOrdenTrabajoDtoListFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción atrapada: $e");
    }

    return null;
  }

  Future<List<HgResponseOrdenTrabajoDto>?> getAllTrackingOrdenTrabajoxnumero(
      String id,
      String dfecha,
      String idplacatracto,
      String bactivo,
      String idcentrocosto,
      String ccentrocosto,
      String supervisor,
      String taller) async {
    var clientrf = http.Client();
    var url_ot = '$_hgapiEndpoint/consultarordentrabajoxid';
    var uri_ot = Uri.parse(url_ot);

    String jsonBody = jsonEncode({
      "id": id,
      "dfecha": null,
      "idplacatracto": null,
      "bactivo": null,
      "idcentrocosto": null,
      "ccentrocosto": null,
      "supervisor": null,
      "taller": null,
    });

    try {
      var response = await clientrf.post(
        uri_ot,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        //print("Respuesta: ${response.body}");
        if (response.body == "[]") {
          return null;
        } else {
          return hgResponseOrdenTrabajoDtoListFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción atrapada: $e");
    }
    return null;
  }

  Future<List<HgResponseOrdenTrabajoDto>?> getAllTrackingOrdenTrabajoxplaca(
      String id,
      String dfecha,
      String idplacatracto,
      String bactivo,
      String idcentrocosto,
      String ccentrocosto,
      String supervisor,
      String taller) async {
    var clientrf = http.Client();
    var url_ot = '$_hgapiEndpoint/consultarordentrabajoxplaca';
    var uri_ot = Uri.parse(url_ot);

    String jsonBody = jsonEncode({
      "id": null,
      "dfecha": null,
      "idplacatracto": idplacatracto,
      "bactivo": null,
      "idcentrocosto": null,
      "ccentrocosto": null,
      "supervisor": null,
      "taller": null,
    });

    try {
      var response = await clientrf.post(
        uri_ot,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        //print("Respuesta: ${response.body}");
        if (response.body == "[]") {
          return null;
        } else {
          return hgResponseOrdenTrabajoDtoListFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción atrapada: $e");
    }
    return null;
  }

  Future<List<HgDetalleOrdenTrabajoDto>?> getAllTrackingDetalleOrdenTrabajo(
      List<HgDetalleOrdenTrabajoBodyDto> dotbody) async {
    var clientrf = http.Client();
    var url_rf = '$_hgapiEndpoint/updatevariosdetalleordentrabajo';
    var uri_rf = Uri.parse(url_rf);

    String jsonBody = hgDetalleOrdenTrabajoBodyDtoToJson(dotbody);

    try {
      var response = await clientrf.post(
        uri_rf,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        //print("Respuesta: ${response.body}");
        if (response.body == "[]") {
          return null;
        } else {
          return hgDetalleOrdenTrabajoDtoFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
        }
      } else {
        print("Error en la solicitud: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción atrapada: $e");
    }
    return null;
  }

  Future<List<HgEmpleadoMantenimientoDto>?> getAllEmpleadosMantenimiento() async {
    var client = http.Client();
    var url = 'http://extranetservicio.hagemsa.org/api/empleado/empleadoMantenimiento';
    var uri = Uri.parse(url);

    String jsonBody = jsonEncode({});

    try {
      var response = await client.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        //print("Respuesta: ${response.body}");
        if (response.body == "[]" || response.body.isEmpty) {
          return null;
        } else {
          var empleados = hgEmpleadoMantenimientoDtoFromJson(
              const Utf8Decoder().convert(response.bodyBytes));
          
          // Filtrar solo empleados activos
          var empleadosActivos = empleados.where((e) => e.activo == 1).toList();
          
          // Ordenar alfabéticamente por apellido paterno
          empleadosActivos.sort((a, b) {
            String apellidoA = a.apellidopaterno ?? '';
            String apellidoB = b.apellidopaterno ?? '';
            return apellidoA.compareTo(apellidoB);
          });
          
          return empleadosActivos;
        }
      } else {
        print("Error en la solicitud: Código ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción atrapada: $e");
    }
    return null;
  }
}
