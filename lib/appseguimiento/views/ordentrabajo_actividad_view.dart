import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalledetalleordentrabajobodydto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgdetalleordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgresponseordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/service/tracking_service_detalleordentrabajo.dart';

class OrdentrabajoActividad extends StatefulWidget {
  const OrdentrabajoActividad({
    super.key,
    required this.itemTrack,
    required this.ot,
  });

  final HgOperadorOtroDto itemTrack;
  final HgResponseOrdenTrabajoDto ot;

  @override
  State<OrdentrabajoActividad> createState() =>
      _OrdentrabajoActividad(operador: itemTrack, ot: ot);
}

class _OrdentrabajoActividad extends State<OrdentrabajoActividad> {
  _OrdentrabajoActividad({required this.operador, required this.ot});

  final HgOperadorOtroDto operador;
  final HgResponseOrdenTrabajoDto ot;
  final List<HgDetalleOrdenTrabajoDto> _detallesModificados = [];
  List<HgDetalleOrdenTrabajoDto>? inittrackings;

  TextEditingController nombreoperador = TextEditingController();
  TextEditingController cargo = TextEditingController();

  bool _hayCambios = false;

  @override
  void initState() {
    super.initState();
    nombreoperador.text =
        "${operador.nombres}, ${operador.apellidopaterno} ${operador.apellidomaterno}";
    cargo.text = "${operador.ccargo}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actividades Orden de Trabajo"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(28, 245, 66, 66),
        foregroundColor: const Color.fromARGB(255, 224, 46, 48),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text("Orden de Trabajo: ${ot.ot!.id}"),
                    const SizedBox(height: 10),
                    Text("Placa: ${ot.ot!.idplacatracto}"),
                    const SizedBox(height: 10),
                    Text("Nombre: ${nombreoperador.text}"),
                    const SizedBox(height: 10),
                    Text("Cargo: ${cargo.text}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (ot.listadot != null)
              for (int i = 0; i < ot.listadot!.length; i++)
                _buildActividadCard(i),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: guardarActividades,
              icon: const Icon(Icons.save),
              label: const Text("Guardar"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Color.fromARGB(255, 224, 46, 48),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActividadCard(int index) {
    final detalle = ot.listadot![index];
    final cerrada = detalle.bcerrada ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Actividad ${index + 1}: ${detalle.cactividad ?? '-'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (cerrada)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "Actividad cerrada",
                    style: TextStyle(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _buildTimeField(
                label: "Fecha y Hora Inicio",
                initialMillis: detalle.dtiempoinicio,
                onTimeSelected: (newMillis) {
                  setState(() {
                    detalle.dtiempoinicio = newMillis;
                    _hayCambios = true;
                    if (!_detallesModificados.contains(detalle)) {
                      _detallesModificados.add(detalle);
                    }
                  });
                },
                enabled: !cerrada,
              ),
              const SizedBox(height: 8),
              _buildTimeField(
                label: "Fecha y Hora Fin",
                initialMillis: detalle.dtiempofin,
                onTimeSelected: (newMillis) {
                  setState(() {
                    detalle.dtiempofin = newMillis;
                    _hayCambios = true;
                    if (!_detallesModificados.contains(detalle)) {
                      _detallesModificados.add(detalle);
                    }
                  });
                },
                enabled: !cerrada,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> guardarActividades() async {
    if (_hayCambios && _detallesModificados.isNotEmpty) {
      final List<HgDetalleOrdenTrabajoBodyDto> listdotbody = [];

      for (var detalle in _detallesModificados) {
        final dotbody = HgDetalleOrdenTrabajoBodyDto();
        dotbody.iddetalleordentrabajo = detalle.id?.toString();
        dotbody.idempleadoext = ot.ot?.idacopleext?.toString();
        dotbody.ccargoemp = cargo.text;
        dotbody.cnombreemp = nombreoperador.text;
        dotbody.dtiempoinicio = detalle.dtiempoinicio != null
            ? _formatearFecha(detalle.dtiempoinicio!)
            : null;
        dotbody.dtiempofin = detalle.dtiempofin != null
            ? _formatearFecha(detalle.dtiempofin!)
            : null;
        listdotbody.add(dotbody);
      }

      final trackingServiceDetalleOrdenTrabajo =
          TrackingServiceDetalleOrdenTrabajo(
        datelleOrdenTrabajoBody: listdotbody,
      );

      inittrackings = await trackingServiceDetalleOrdenTrabajo
          .getAllTrackingDetalleOrdenTrabajo();
      setState(() {
        if (inittrackings != null && inittrackings!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardo Correctamente.')),
          );
          _hayCambios = false;
          _detallesModificados.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error No se Guardo.')),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se detectaron cambios.')),
      );
    }
  }

  String _formatearFecha(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');

    final year = date.year;
    final month = twoDigits(date.month);
    final day = twoDigits(date.day);
    final hour = twoDigits(date.hour);
    final minute = twoDigits(date.minute);
    final second = twoDigits(date.second);
    final millisecond = threeDigits(date.millisecond);

    return "$year-$month-$day $hour:$minute:$second.$millisecond";
  }

  Future<void> _selectDateTime({
    required BuildContext context,
    required String label,
    required DateTime? initialDateTime,
    required Function(int) onSelected,
    required bool enabled,
    required TextEditingController controller,
  }) async {
    if (!enabled) return;

    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialDateTime != null
            ? TimeOfDay.fromDateTime(initialDateTime)
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        controller.text =
            "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year} ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";

        onSelected(combined.millisecondsSinceEpoch);
      }
    }
  }

  Widget _buildTimeField({
    required String label,
    required int? initialMillis,
    required Function(int) onTimeSelected,
    required bool enabled,
  }) {
    DateTime? initial = initialMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(initialMillis)
        : null;

    final controller = TextEditingController(
      text: initial != null
          ? "${initial.day.toString().padLeft(2, '0')}/${initial.month.toString().padLeft(2, '0')}/${initial.year} ${initial.hour.toString().padLeft(2, '0')}:${initial.minute.toString().padLeft(2, '0')}"
          : '',
    );

    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.access_time),
      ),
      onTap: () => _selectDateTime(
        context: context,
        label: label,
        initialDateTime: initial,
        enabled: enabled,
        controller: controller,
        onSelected: onTimeSelected,
      ),
    );
  }
}
