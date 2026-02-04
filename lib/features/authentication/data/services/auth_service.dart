import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/authentication/data/models/empleado.dart';

class AuthService {
  final _api = TrackingApi();
  
  Future<List<HgEmpleadoMantenimientoDto>?> getAllEmpleadosMantenimiento() async =>
      _api.getAllEmpleadosMantenimiento();
}
