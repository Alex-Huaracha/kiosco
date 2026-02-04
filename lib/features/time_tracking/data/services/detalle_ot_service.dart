import 'package:hgtrack/core/network/api_client.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_body.dart';
import 'package:hgtrack/features/time_tracking/data/models/detalle_orden_trabajo.dart';

class DetalleOTService {
  final _api = TrackingApi();
  final List<HgDetalleOrdenTrabajoBodyDto> datelleOrdenTrabajoBody;

  DetalleOTService({
    required this.datelleOrdenTrabajoBody,
  });

  Future<List<HgDetalleOrdenTrabajoDto>?>
      getAllTrackingDetalleOrdenTrabajo() async =>
          _api.getAllTrackingDetalleOrdenTrabajo(this.datelleOrdenTrabajoBody);
}
