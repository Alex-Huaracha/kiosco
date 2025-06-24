import 'package:hgtrack/appseguimiento/model/hgresponseordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/provider/tracking_api.dart';

class TrackingServiceOrdenTrabajo {
  final _api = TrackingApi();
  final String id;
  final String dfecha;
  final String idplacatracto;
  final String bactivo;
  final String idcentrocosto;
  final String ccentrocosto;
  final String supervisor;
  final String taller;
  TrackingServiceOrdenTrabajo({
    required this.id,
    required this.dfecha,
    required this.idplacatracto,
    required this.bactivo,
    required this.idcentrocosto,
    required this.ccentrocosto,
    required this.supervisor,
    required this.taller,
  });

  Future<List<HgResponseOrdenTrabajoDto>?> getAllTrackingOrdenTrabajo() async =>
      _api.getAllTrackingOrdenTrabajo(
        this.id,
        this.dfecha,
        this.idplacatracto,
        this.bactivo,
        this.idcentrocosto,
        this.ccentrocosto,
        this.supervisor,
        this.taller,
      );
  Future<List<HgResponseOrdenTrabajoDto>?>
      getAllTrackingOrdenTrabajoxnumero() async =>
          _api.getAllTrackingOrdenTrabajoxnumero(
            this.id,
            this.dfecha,
            this.idplacatracto,
            this.bactivo,
            this.idcentrocosto,
            this.ccentrocosto,
            this.supervisor,
            this.taller,
          );
  Future<List<HgResponseOrdenTrabajoDto>?>
      getAllTrackingOrdenTrabajoxplaca() async =>
          _api.getAllTrackingOrdenTrabajoxplaca(
            this.id,
            this.dfecha,
            this.idplacatracto,
            this.bactivo,
            this.idcentrocosto,
            this.ccentrocosto,
            this.supervisor,
            this.taller,
          );
}
