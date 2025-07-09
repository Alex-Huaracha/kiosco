import 'package:flutter/material.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadorotrodto_model.dart';
import 'package:hgtrack/appseguimiento/service/tracking_service_operador.dart';
import 'package:hgtrack/appseguimiento/views/menu_form_view.dart';
import 'package:hgtrack/appseguimiento/model/hgoperadordto_model.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var mensajeUsr = '';
  var mensajePsw = '';
  var mensajeTotal = '';

  List<HgOperadorOtroDto>? inittrackingsotro;
  List<HgOperadorDto>? inittrackingsfinal;
  bool isLoading = false;
  TextEditingController dni = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(left: 50, right: 50),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text(
              'Control Tiempo OT',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 224, 46, 48),
              ),
            ),
            const SizedBox(
              width: 50,
              height: 20,
            ),
            const Image(
              image: AssetImage('assets/icon/logo.png'),
              height: 140,
            ),
            const SizedBox(
              width: 50,
              height: 10,
            ),
            textUser(usr: dni),
            textmsgurs(mensajeUsr: mensajeUsr),
            const SizedBox(
              width: 50,
              height: 20,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 40),
                backgroundColor: Color.fromARGB(255, 224, 46, 48),
              ),
              onPressed: () {
                mensajeTotal = '';
                mensajeUsr = dni.text.isEmpty ? 'Ingrese su DNI' : '';
                if (mensajeUsr.isEmpty) {
                  if ((dni.text.isNotEmpty) && dni.text.length >= 8) {
                    isLoading = dni.text.isNotEmpty;
                    if (!isLoading) mensajeTotal = 'Ingrese DNI';
                    if (isLoading) loadOperador();
                  } else {
                    mensajeTotal = 'Datos incorrectos, intente de nuevo';
                  }
                }
                setState(() {});
              },
              child: Text('Ingresar', style: TextStyle(color: Colors.white)),
            ),
            textmsgtotal(mensajeTotal: mensajeTotal),
            Resultado(cargando: isLoading),
          ]),
        ),
      ),
    );
  }

  Future<void> loadOperador() async {
    final trackingServiceOperador = TrackingServiceOperador(dni: dni.text);

    inittrackingsotro =
        await trackingServiceOperador.getAllTrackingOperadorOtro();

    setState(() {
      if (inittrackingsotro != null && inittrackingsotro!.isNotEmpty) {
        isLoading = false;
        mensajeTotal = '';
        mensajeTotal = 'Se recibieron los datos';
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MenuForm(itemTrack: inittrackingsotro![0])));
      } else {
        isLoading = false;
        mensajeTotal = '';
        mensajeTotal = 'No se encontro el DNI';
      }
    });
  }
}

class textmsgtotal extends StatelessWidget {
  const textmsgtotal({
    super.key,
    required this.mensajeTotal,
  });

  final String mensajeTotal;

  @override
  Widget build(BuildContext context) {
    return Text(mensajeTotal,
        style: TextStyle(color: Color.fromARGB(255, 224, 46, 48)));
  }
}

class textmsgpsw extends StatelessWidget {
  const textmsgpsw({
    super.key,
    required this.mensajePsw,
  });

  final String mensajePsw;

  @override
  Widget build(BuildContext context) {
    return Text(
      mensajePsw,
      style: TextStyle(color: Color.fromARGB(255, 224, 46, 48)),
    );
  }
}

class textmsgurs extends StatelessWidget {
  const textmsgurs({
    super.key,
    required this.mensajeUsr,
  });

  final String mensajeUsr;

  @override
  Widget build(BuildContext context) {
    return Text(
      mensajeUsr,
      style: TextStyle(color: Color.fromARGB(255, 224, 46, 48)),
    );
  }
}

class textpas extends StatelessWidget {
  const textpas({
    super.key,
    required this.psw,
  });

  final TextEditingController psw;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: psw,
      obscureText: true,
      decoration: InputDecoration(
        hintText: "ingrese clave",
      ),
    );
  }
}

class textUser extends StatelessWidget {
  const textUser({
    super.key,
    required this.usr,
  });

  final TextEditingController usr;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: usr,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "Ingrese DNI",
        labelText: 'DNI',
      ),
    );
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
