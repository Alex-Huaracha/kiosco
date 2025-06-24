import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';
import 'package:hgtrack/appseguimiento/model/hgresponseordentrabajodto_model.dart';
import 'package:hgtrack/appseguimiento/service/tracking_service_ordentrabajo.dart';
import 'package:hgtrack/appseguimiento/views/orden_trabajo_lista.dart';

class TrackForm extends StatefulWidget {
  const TrackForm({super.key, required this.itemTrack});
  final HgOperadorOtroDto itemTrack;

  @override
  State<TrackForm> createState() => _TrackFormState(operador: itemTrack);
}

class _TrackFormState extends State<TrackForm> {
  _TrackFormState({required this.operador});
  final HgOperadorOtroDto operador;

  List<HgResponseOrdenTrabajoDto>? inittrackingsnumero;
  List<HgResponseOrdenTrabajoDto>? inittrackingsplaca;

  bool isLoading = false;
  DateTime now = DateTime.now();
  bool guardar = true;
  String motivoguardar = "";

  TextEditingController numerocel = TextEditingController();
  TextEditingController placa = TextEditingController();

  var mensajeNumeroCel = '';
  var mensajePlaca = '';
  var mensajeTotal = '';
  var mensajeResultado = '';

  @override
  void initState() {
    super.initState();
    placa.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    placa.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Buscar Orden de Trabajo"),
          centerTitle: true,
          backgroundColor: Color.fromARGB(28, 245, 66, 66),
          foregroundColor: Color.fromARGB(255, 224, 46, 48)),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              children: [
                const SizedBox(height: 40),
                TextField(
                  controller: numerocel,
                  keyboardType: TextInputType.number,
                  enabled: placa.text.isEmpty,
                  decoration: InputDecoration(
                    hintText: "Ingrese Numero de Orden de Trabajo",
                    labelText: 'Numero OT',
                    suffixIcon: numerocel.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              numerocel.clear();
                              setState(() {
                                guardar = false;
                                mensajeTotal = '';
                                motivoguardar = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    final esNumero = RegExp(r'^[0-9]+$');
                    setState(() {
                      if (value.isEmpty) {
                        mensajeTotal = '';
                      } else if (!esNumero.hasMatch(value)) {
                        mensajeTotal = 'Numero OT: Solo se permiten números';
                        guardar = false;
                        motivoguardar = mensajeTotal;
                      } else {
                        guardar = true;
                        mensajeTotal = '';
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: placa,
                  enabled: numerocel.text.isEmpty,
                  decoration: InputDecoration(
                    hintText: "Ingrese Placa",
                    labelText: 'Placa',
                    suffixIcon: placa.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              placa.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 40),
                    backgroundColor: const Color.fromARGB(255, 224, 46, 48),
                  ),
                  onPressed: () {
                    final tieneOT = numerocel.text.isNotEmpty;
                    final tienePlaca = placa.text.isNotEmpty;

                    if (tieneOT || tienePlaca) {
                      mensajeTotal = '';
                      mensajeResultado = '';
                      isLoading = true;
                      setState(() {});

                      if (tieneOT) {
                        loadListaOTxnumero();
                      } else if (tienePlaca) {
                        loadListaOTxplaca();
                      }
                    } else {
                      mensajeTotal = 'Debe ingresar Número OT o Placa';
                      setState(() {});
                    }
                  },
                  child: const Text('Buscar',
                      style: TextStyle(color: Colors.white)),
                ),
                Text(mensajeTotal,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 224, 46, 48))),
                Text(mensajeResultado,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 1, 252, 156))),
                Resultado(cargando: isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loadListaOTxnumero() async {
    final trackingServiceListaOrdenTrabajoxnumero = TrackingServiceOrdenTrabajo(
      id: numerocel.text,
      dfecha: "",
      idplacatracto: "",
      bactivo: "",
      idcentrocosto: "",
      ccentrocosto: "",
      supervisor: "",
      taller: "",
    );
    inittrackingsnumero = await trackingServiceListaOrdenTrabajoxnumero
        .getAllTrackingOrdenTrabajoxnumero();
    setState(() {
      if (inittrackingsnumero != null && inittrackingsnumero!.isNotEmpty) {
        isLoading = false;
        mensajeTotal = '';
        mensajeTotal = 'Se recibieron los datos';
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ListaOrdenTrabajo(
                    listtracking: inittrackingsnumero!, itemTrack: operador)));
      } else {
        isLoading = false;
        mensajeTotal = '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No hay Ordenes de Trabajo Activa con ese Numero"),
            showCloseIcon: true,
          ),
        );
      }
    });
  }

  Future<void> loadListaOTxplaca() async {
    final trackingServiceListaOrdenTrabajoxplaca = TrackingServiceOrdenTrabajo(
      id: "",
      dfecha: "",
      idplacatracto: placa.text,
      bactivo: "",
      idcentrocosto: "",
      ccentrocosto: "",
      supervisor: "",
      taller: "",
    );

    inittrackingsplaca = await trackingServiceListaOrdenTrabajoxplaca
        .getAllTrackingOrdenTrabajoxplaca();
    setState(() {
      //print(inittrackings4?.length);
      if (inittrackingsplaca != null && inittrackingsplaca!.isNotEmpty) {
        isLoading = false;
        mensajeTotal = '';
        mensajeTotal = 'Se recibieron los datos';
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ListaOrdenTrabajo(
                    listtracking: inittrackingsplaca!, itemTrack: operador)));
      } else {
        isLoading = false;
        mensajeTotal = '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No hay Ordenes de Trabajo Activa con esa Placa"),
            showCloseIcon: true,
          ),
        );
      }
    });
  }
}

class Resultado extends StatelessWidget {
  const Resultado({super.key, required this.cargando});
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    if (cargando)
      return const Center(child: CircularProgressIndicator());
    else
      return Text("");
  }
}
