import 'package:hgtrack/appseguimiento/model/hgdetalledetalleordentrabajobodydto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalleordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/provider/tracking_api.dart';

class TrackingServiceDetalleOrdenTrabajo {
  final _api = TrackingApi();
  final List<HgDetalleOrdenTrabajoBodyDto> datelleOrdenTrabajoBody;

  TrackingServiceDetalleOrdenTrabajo({
    required this.datelleOrdenTrabajoBody,
  });

  Future<List<HgDetalleOrdenTrabajoDto>?>
      getAllTrackingDetalleOrdenTrabajo() async =>
          _api.getAllTrackingDetalleOrdenTrabajo(this.datelleOrdenTrabajoBody);
}
