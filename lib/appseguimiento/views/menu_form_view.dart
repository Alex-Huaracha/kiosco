import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgresponseordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/service/tracking_service_ordentrabajo.dart';
import 'package:hgtrack/appseguimiento/views/orden_trabajo_lista.dart';
import 'package:hgtrack/appseguimiento/views/tracking_form_view.dart';

class MenuForm extends StatefulWidget {
  const MenuForm({super.key, required this.itemTrack});
  final HgOperadorOtroDto itemTrack;

  @override
  State<MenuForm> createState() => _MenuFormState(operador: itemTrack);
}

class _MenuFormState extends State<MenuForm> {
  _MenuFormState({required this.operador});
  final HgOperadorOtroDto operador;

  List<HgResponseOrdenTrabajoDto>? inittrackings4;

  TextEditingController nombreoperador = TextEditingController();
  TextEditingController dni = TextEditingController();
  TextEditingController cuenta = TextEditingController();
  TextEditingController cargo = TextEditingController();

  @override
  void initState() {
    super.initState();
    nombreoperador.text =
        "${operador.nombres}, ${operador.apellidopaterno} ${operador.apellidomaterno}";
    dni.text = "${operador.numerodocumento}";
    cuenta.text = "${operador.cuenta}";
    cargo.text = "${operador.ccargo}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Menu"),
        centerTitle: true,
        backgroundColor: Color.fromARGB(28, 245, 66, 66),
        foregroundColor: Color.fromARGB(255, 224, 46, 48),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text("Nombre:  ${nombreoperador.text}"),
                      const SizedBox(height: 10),
                      Text("DNI: ${dni.text}"),
                      const SizedBox(height: 10),
                      Text("Cuenta: ${cuenta.text}"),
                      const SizedBox(height: 10),
                      Text("Cargo: ${cargo.text}"),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 80,
                  child: ElevatedButton.icon(
                    onPressed: loadOperador,
                    icon: Icon(Icons.search, size: 32),
                    label: Text(
                      'Buscar Orden de Trabajo',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 80,
                  child: ElevatedButton.icon(
                    onPressed: loadListaOT,
                    icon: Icon(Icons.car_repair, size: 32),
                    label: Text(
                      'Lista Orden de Trabajo',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loadOperador() async {
    setState(() {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TrackForm(itemTrack: operador)));
    });
  }

  Future<void> loadListaOT() async {
    final trackingServiceListaOrdenTrabajo = TrackingServiceOrdenTrabajo(
      id: "",
      dfecha: "",
      idplacatracto: "",
      bactivo: "",
      idcentrocosto: "",
      ccentrocosto: "",
      supervisor: "",
      taller: "",
    );

    inittrackings4 =
        await trackingServiceListaOrdenTrabajo.getAllTrackingOrdenTrabajo();
    setState(() {
      if (inittrackings4 != null && inittrackings4!.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ListaOrdenTrabajo(
                    listtracking: inittrackings4!, itemTrack: operador)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No hay Ordenes de Trabajo Activas"),
            showCloseIcon: true,
          ),
        );
      }
    });
  }
}
