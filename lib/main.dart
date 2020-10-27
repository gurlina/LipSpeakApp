import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:lipspeak/phrasebook.dart';
import 'package:lipspeak/util/colors.dart';
//import 'package:flutter_camera/camera_screen.dart';

import 'package:firebase_core/firebase_core.dart';

import 'camera_screen.dart';

//const Color barColor = const Color(0x20000000);
const Color barColor = const Color(0x50534bae);

ThemeData _buildLipspeakTheme() {
  final ThemeData base = ThemeData.light();

  return base.copyWith(
      accentColor: primaryIndigoDark,
      primaryColor: primaryIndigo900,
      scaffoldBackgroundColor: secondaryBackgroundWhite,
      hintColor: textOnPrimaryWhite,
      cardColor: secondaryOrange400,
      bottomAppBarColor: barColor,
      textTheme: _buildLipspeakTextTheme(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderSide: BorderSide(color: primaryIndigoLight),
              borderRadius: BorderRadius.circular(12))),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
          elevation: 7,
          //splashColor: primaryIndigoLight,
          backgroundColor: primaryIndigoDark));
}

_buildLipspeakTextTheme(TextTheme base) {
  return base.copyWith(
      //bodyText2: TextStyle(color: Colors.deepPurple, fontSize: 20),
      bodyText1: TextStyle(color: Colors.indigo.shade900, fontSize: 20));
  //.apply(fontFamily: "Rubik"));
}

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]).then((_) {
//     runApp(MyApp());
//   });
// }

// void main() async {
//   // Must initialize the default Firebase app prior to calling BoardApp
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   runApp(new MaterialApp(
//     home: PhraseBook(),
//   ));
// }

void main() async {
  // Must initialize the default Firebase app prior to calling BoardApp
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      //   brightness: Brightness.dark,
      //   backgroundColor: Colors.black,
      //   bottomAppBarColor: barColor,
      // ),
      theme: _buildLipspeakTheme(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _cameraKey = GlobalKey<CameraScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).backgroundColor,
      body: CameraScreen(
        key: _cameraKey,
      ),
    );
  }
}
