import 'package:hgtrack/appseguimiento/model/hgempleadomantenimiento_model.dart';
import 'package:hgtrack/appseguimiento/provider/tracking_api.dart';

class TrackingServiceEmpleadoMantenimiento {
  final _api = TrackingApi();
  
  Future<List<HgEmpleadoMantenimientoDto>?> getAllEmpleadosMantenimiento() async =>
      _api.getAllEmpleadosMantenimiento();
}
