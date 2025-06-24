import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgresponseordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/views/ordentrabajo_actividad_view.dart';

class ListaOrdenTrabajo extends StatefulWidget {
  const ListaOrdenTrabajo(
      {super.key, required this.listtracking, required this.itemTrack});

  final List<HgResponseOrdenTrabajoDto> listtracking;
  final HgOperadorOtroDto itemTrack;

  @override
  State<ListaOrdenTrabajo> createState() =>
      _ListaOrdenTrabajo(listaot: listtracking, operador: itemTrack);
}

class _ListaOrdenTrabajo extends State<ListaOrdenTrabajo> {
  _ListaOrdenTrabajo({required this.listaot, required this.operador});
  final List<HgResponseOrdenTrabajoDto> listaot;
  final HgOperadorOtroDto operador;

  TextEditingController id = TextEditingController();

  HgResponseOrdenTrabajoDto? inittrackingsresumen;

  @override
  void initState() {
    super.initState();
    id.text = listaot[0].ot!.id.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista Orden de Trabajo"),
          centerTitle: true,
          backgroundColor: Color.fromARGB(28, 245, 66, 66),
          foregroundColor: Color.fromARGB(255, 224, 46, 48),
        ),
        body: Container(child: getWidget()));
  }

  Widget getWidget() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        for (var track in listaot) ...{
          Card(
            elevation: 5,
            child: _SampleCard(
              filaDto: track,
              inittrackingsresumenfin: inittrackingsresumen,
              operador: operador,
            ),
          ),
        }
      ],
    );
  }
}

class _SampleCard extends StatefulWidget {
  const _SampleCard({
    required this.filaDto,
    this.inittrackingsresumenfin,
    required this.operador,
  });
  final HgResponseOrdenTrabajoDto filaDto;
  final HgResponseOrdenTrabajoDto? inittrackingsresumenfin;
  final HgOperadorOtroDto operador;

  @override
  State<_SampleCard> createState() => _SampleCardState();
}

class _SampleCardState extends State<_SampleCard> {
  HgResponseOrdenTrabajoDto? resumen;

  @override
  void initState() {
    super.initState();
    resumen = widget.inittrackingsresumenfin;
  }

  String _formatearFecha(int? millis) {
    if (millis == null) return '-';
    final fecha = DateTime.fromMillisecondsSinceEpoch(millis);

    String dosDigitos(int n) => n.toString().padLeft(2, '0');

    final anio = fecha.year;
    final mes = dosDigitos(fecha.month);
    final dia = dosDigitos(fecha.day);
    final hora = dosDigitos(fecha.hour);
    final minuto = dosDigitos(fecha.minute);

    return '$anio-$mes-$dia $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    const double fontSizeTitle = 16;
    const double fontSizeSubTitle = 12;
    return Container(
      child: Column(children: <Widget>[
        Text(
          'Orden de Trabajo: ${widget.filaDto.ot!.id}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.left,
        ),
        ListTile(
          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          title: Text(
              ' Fecha: ' +
                  _formatearFecha(widget.filaDto.ot!.dfecha) +
                  '\n Placa: ${widget.filaDto.ot!.idplacatracto}' +
                  '\n Kilometraje: ${widget.filaDto.ot!.nkilometraje}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSizeTitle,
              )),
          subtitle: Text('',
              style: TextStyle(fontSize: fontSizeSubTitle, color: Colors.blue)),
        ),
        ElevatedButton(
          onPressed: () {
            iraActividades();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: Size(200, 40),
            backgroundColor: Color.fromARGB(255, 224, 46, 48),
            foregroundColor: Colors.white,
          ),
          child: Text('Ver Actividades'),
        ),
        if (resumen != null) ...[
          Text('Resumen ID: ${resumen!.ot!.id ?? "-"}'),
        ],
        SizedBox(height: 10)
      ]),
    );
  }

  Future<void> iraActividades() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OrdentrabajoActividad(
                  itemTrack: widget.operador,
                  ot: widget.filaDto,
                )));
  }
}
