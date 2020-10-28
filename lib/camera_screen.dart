import 'dart:io';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lipspeak/model/phrase_book.dart';
import 'package:lipspeak/phrasebook.dart';
import 'package:lipspeak/speech_generator.dart';
import 'package:lipspeak/util/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

enum TtsState { playing, stopped }

class CameraScreen extends StatefulWidget {
  CameraScreen({Key key}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController _controller;
  List<CameraDescription> _cameras;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRecording = false;
  bool _busy = false;

  //final List<Phrase> phraseBook = Phrase.getPhraseBook();
  Future<List<PhraseFS>> phraseBookFS;

  SpeechGenerator speechGen = SpeechGenerator();
  int _currentPhraseIdx = 0;

  String _newVoiceText;

  @override
  void initState() {
    _initCamera();
    super.initState();
    _configureSpeechGen();
    phraseBookFS = PhraseFS.getPhraseBook();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    stackChildren.clear();

    if (_controller != null) {
      if (!_controller.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Build the Stack of Widgets
    if (!_busy) {
      stackChildren.add(_buildCameraPreview());

      stackChildren.add(Positioned(
        top: 24.0,
        right: 12.0,
        child: IconButton(
            icon: Icon(
              Icons.switch_camera,
              color: Colors.white,
              size: 30,
            ),
            onPressed: _onCameraSwitch),
      ));
    } else {
      // stackChildren.add(const Opacity(
      //   child: ModalBarrier(dismissible: false, color: secondaryOrangeDark),
      //   opacity: 0.5,
      // ));
      stackChildren
          .add(ModalBarrier(dismissible: false, color: secondaryOrange400));
      stackChildren.add(const Center(
          child: SizedBox(
        height: 200,
        width: 200,
        child: CircularProgressIndicator(
          strokeWidth: 10.0,
        ),
      )));
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     children: <Widget>[
      //       Image.asset(
      //         'images/header.jpg',
      //         fit: BoxFit.contain,
      //         height: 120.0,
      //       ),
      //     ],
      //   ),
      // ),
      appBar: AppBar(
        title: Text("Speech Generator"),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 160,
              child: DrawerHeader(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("images/header.jpg"),
                        fit: BoxFit.cover)),
                child: Text(""),
              ),
            ),
            ListTile(
                leading: Icon(Icons.book_outlined),
                title: Text("Phrase Book"),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(builder: (context) => PhraseBook()),
                //   );
                // },
                onTap: () {
                  _navigateToPhrasebook(context);
                }),
            ListTile(
              leading: Icon(Icons.mic),
              title: Text("Speech Settings"),
              onTap: () => {},
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text("Help"),
              onTap: () => {},
            )
          ],
        ),
      ),
      key: _scaffoldKey,
      extendBody: true,
      body: Stack(
        children: stackChildren,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Future<void> _initCamera() async {
    // get the list of available cameras
    _cameras = await availableCameras();

    // initialize CameraController (_camera[1] is the front camera)
    _controller = CameraController(_cameras[1], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future<void> _configureSpeechGen() async {
    await speechGen.configureTts();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _deleteMediaFiles() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/media';
    Directory(dirPath).deleteSync(recursive: true);
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    return ClipRect(
      child: Container(
        child: Transform.scale(
          scale: _controller.value.aspectRatio / size.aspectRatio,
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: CameraPreview(_controller),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCameraSwitch() async {
    final CameraDescription cameraDescription =
        (_controller.description == _cameras[0]) ? _cameras[1] : _cameras[0];
    if (_controller != null) {
      await _controller.dispose();
    }

    _controller = CameraController(cameraDescription, ResolutionPreset.medium);

    _controller.addListener(() {
      if (mounted) setState(() {});
      if (_controller.value.hasError) {
        showInSnackBar('Camera error ${_controller.value.errorDescription}');
      }
    });

    try {
      await _controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBottomNavigationBar() {
    IconButton _button;

    if (_busy) {
      _button = IconButton(
          icon: Icon(
            Icons.cancel_sharp,
            size: 28.0,
            color: Colors.black,
          ),
          onPressed: () {
            stopProcessing();
          });
    } else {
      _button = IconButton(
          icon: Icon(
            Icons.videocam,
            size: 28.0,
            color: (_isRecording) ? Colors.red : Colors.black,
          ),
          onPressed: () {
            if (_isRecording) {
              stopVideoRecording();
            } else {
              startVideoRecording();
            }
          });
    }

    return Container(
      color: Theme.of(context).bottomAppBarColor,
      height: 100.0,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 28.0,
            child: _button,
          ),
        ],
      ),
    );
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> startVideoRecording() async {
    debugPrint('startVideoRecording');

    if (!_controller.value.isInitialized) {
      return null;
    }

    setState(() {
      _isRecording = true;
    });

    final Directory extDir = await getApplicationDocumentsDirectory();
    debugPrint('Application directory: ${extDir.path}');

    final String dirPath = '${extDir.path}/media';
    await Directory(dirPath).create(recursive: true);
    //Directory(dirPath).deleteSync();
    final String filePath = '$dirPath/${_timestamp()}.mp4';

    if (_controller.value.isRecordingVideo) {
      // a recording is already started, do nothing
      return null;
    }

    Directory(dirPath)
        .list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
      debugPrint('Media file: ${entity.path}');
      //Directory(entity.path).deleteSync(recursive: true);
    });

    try {
      await _controller.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await _controller.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _busy = true;
      });

      await _processVideo();
    } on CameraException catch (e) {
      _showCameraException(e);
      setState(() {
        _isRecording = false;
        _busy = false;
      });
      return null;
    }
  }

  Future<void> stopProcessing() async {
    var result = await speechGen.stop();
    if (result == 1) {
      setState(() {
        _busy = false;
      });
    }
  }

  Future analyzeVideo() async {
    // TODO: placeholder for video processing
    // DEBUG: emulate processing delay
    debugPrint('busy processing...');
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> _processVideo() async {
    // TODO - add processing

    await analyzeVideo();

    _deleteMediaFiles();

    if (!_busy) return;

    await _onPhraseChange(_currentPhraseIdx);
    await _speak();

    setState(() {
      _busy = false;
    });
  }

  Future<void> _onPhraseChange(int index) async {
    // TODO: move phrasebook update to video processing
    setState(() {
      //_newVoiceText = phraseBook[index].text;
      phraseBookFS.then((value) {
        _newVoiceText = value[index].text;
        _currentPhraseIdx = (_currentPhraseIdx + 1) % value.length;
      });
      //_newVoiceText = phraseBookFS[index].text;

      // debug: increment phrase index for now
      //_currentPhraseIdx = (_currentPhraseIdx + 1) % phraseBookFS.length;
    });
  }

  Future _speak() async {
    debugPrint("_speak()");

    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        debugPrint("$_newVoiceText");
        await speechGen.speakPhrase(_newVoiceText);
      }
    }
  }

  _navigateToPhrasebook(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PhraseBook(
                speechGen: this.speechGen,
              )),
    );

    phraseBookFS = PhraseFS.getPhraseBook();

    // After the Selection Screen returns a result, hide any previous snackbars
    // and show the new result.
    // Scaffold.of(context)
    //   ..removeCurrentSnackBar()
    //   ..showSnackBar(SnackBar(content: Text("$result")));
  }
}
