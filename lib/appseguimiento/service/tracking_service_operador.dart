import 'package:hgtrack/appseguimiento/model/hgoperadordto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';
import 'package:hgtrack/appseguimiento/provider/tracking_api.dart';

class TrackingServiceOperador {
  TrackingServiceOperador({
    required this.dni,
  });
  final _api = TrackingApi();
  final String dni;
  Future<List<HgOperadorDto>?> getAllTrackingOperador() async =>
      _api.getAllTrackingOperador(this.dni);
  Future<List<HgOperadorOtroDto>?> getAllTrackingOperadorOtro() async =>
      _api.getAllTrackingOperadorOtro(this.dni);
}
