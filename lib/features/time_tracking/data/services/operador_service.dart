import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/time_tracking/data/models/operador.dart';
import 'package:hgtrack/features/time_tracking/data/models/operador_otro.dart';

class OperadorService {
  OperadorService({
    required this.dni,
  });
  final _api = TrackingApi();
  final String dni;
  Future<List<HgOperadorDto>?> getAllTrackingOperador() async =>
      _api.getAllTrackingOperador(this.dni);
  Future<List<HgOperadorOtroDto>?> getAllTrackingOperadorOtro() async =>
      _api.getAllTrackingOperadorOtro(this.dni);
}
