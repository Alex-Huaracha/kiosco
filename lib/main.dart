import 'package:flutter/material.dart';
import 'package:hgtrack/login/view/login_page.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
     return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'HG Control Tiempo OT',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 224, 46, 48)),
        ),
       home: Login(),     
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
}
