import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lipspeak/model/phrase_book.dart';
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
  bool _cancelled = false;

  final List<Phrase> phraseBook = Phrase.getPhraseBook();
  int _currentPhraseIdx = 0;

  // TTS - need to refactor
  FlutterTts flutterTts;
  String _language = 'en-us';
  double _volume = 0.5;
  double _pitch = 1.0;
  double _rate = 0.5;

  String _newVoiceText;
  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  @override
  void initState() {
    _initCamera();
    super.initState();
    _initTts();
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
            icon: Icon(Icons.switch_camera, color: Colors.white),
            onPressed: _onCameraSwitch),
      ));
    } else {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.deepPurple),
        opacity: 0.8,
      ));
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("LipSpeak"),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text("Phrase Book"),
              onTap: () => {},
            ),
            ListTile(
              title: Text("Speech Settings"),
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
    flutterTts.stop();
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
    var result = await flutterTts.stop();
    if (result == 1) {
      setState(() {
        _busy = false;
        ttsState = TtsState.stopped;
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

    _onPhraseChange(_currentPhraseIdx);
    await _speak();

    setState(() {
      _busy = false;
    });
  }

  void _initTts() {
    flutterTts = FlutterTts();

    flutterTts.setLanguage(_language);

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  void _onPhraseChange(int index) {
    setState(() {
      _newVoiceText = phraseBook[index].text;

      // debug: increment phrase index for now
      _currentPhraseIdx = (_currentPhraseIdx + 1) % phraseBook.length;
    });
  }

  Future _speak() async {
    debugPrint("_speak()");
    await flutterTts.setVolume(_volume);
    await flutterTts.setSpeechRate(_rate);
    await flutterTts.setPitch(_pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        debugPrint("$_newVoiceText");
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(_newVoiceText);
      }
    }
  }
}
