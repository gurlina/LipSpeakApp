//import 'dart:html';
import 'dart:io';
import 'dart:ui';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_ml_vision/firebase_ml_vision.dart';
//import 'package:gallery_saver/gallery_saver.dart';
import 'package:http_parser/http_parser.dart';
//import 'package:lipspeak/face_detector.dart';
import 'package:lipspeak/model/phrase_book.dart';
import 'package:lipspeak/phrasebook.dart';
import 'package:lipspeak/speech_generator.dart';
import 'package:lipspeak/util/colors.dart';
//import 'package:lipspeak/util/face_painter.dart';
import 'package:lipspeak/util/focus_widget.dart';
import 'package:overlay_support/overlay_support.dart';
//import 'package:lipspeak/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class CameraScreen extends StatefulWidget {
  CameraScreen({Key key}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController _controller;
  //ImageRotation _cameraRotation;
  List<CameraDescription> _cameras;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRecording = false;
  bool _busy = false;
  //bool _detectingFaces = false;
  String _videoFile;
  Size imageSize;

  final String serverUri =
      "http://ec2-54-201-218-219.us-west-2.compute.amazonaws.com:5000/handle_form";
  //Face faceDetected;

  //FrameFaceDetector _frameFaceDetector = FrameFaceDetector();

  //final List<Phrase> phraseBook = Phrase.getPhraseBook();
  Future<List<PhraseFS>> phraseBookFS;

  SpeechGenerator speechGen = SpeechGenerator();
  int _currentPhraseIdx = 0;
  String _newVoiceText;

  OverlaySupportEntry _notification;

  @override
  void initState() {
    _initCamera();
    super.initState();

    _configureSpeechGen();
    phraseBookFS = PhraseFS.getPhraseBook();
  }

  @override
  Widget build(BuildContext context) {
    final Widget previewMask =
        CameraFocus.circle(color: Colors.black.withOpacity(0.5));
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

      stackChildren.add(
        Center(
          child: previewMask,
        ),
      );

      // stackChildren.add(CustomPaint(
      //   painter: FacePainter(face: faceDetected, imageSize: imageSize),
      // ));

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
    _controller = CameraController(_cameras[1], ResolutionPreset.medium,
        enableAudio: false);

    // _cameraRotation = rotationIntToImageRotation(
    //   _cameras[1].sensorOrientation,
    // );

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});

      //_frameFaces();
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

    _controller = CameraController(cameraDescription, ResolutionPreset.medium,
        enableAudio: false);

    // _cameraRotation = rotationIntToImageRotation(
    //   cameraDescription.sensorOrientation,
    // );

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

    setState(() {
      _videoFile = filePath;
    });
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await _controller.stopVideoRecording();

      //await GallerySaver.saveVideo(_videoFile);
      //debugPrint("Saved video to Gallery!");

      setState(() {
        _isRecording = false;
        _busy = true;
      });

      await _processVideo();

      // Navigator.of(context).push(new MaterialPageRoute(
      //     builder: (BuildContext context) =>
      //         new VideoPlayerScreen(_videoFile)));
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
        _videoFile = null;
        _notification?.dismiss();
      });
    }
  }

  Future<int> analyzeVideo() async {
    // TODO: placeholder for video processing

    debugPrint('busy processing...');

    int retCode = -1;

    if (File(_videoFile).existsSync()) {
      final mimeTypeData = lookupMimeType(_videoFile).split('/');

      final predictRequest =
          http.MultipartRequest('POST', Uri.parse(serverUri));

      // final file = await http.MultipartFile.fromPath('video', _videoFile,
      //     contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
      final file = await http.MultipartFile.fromPath('file', _videoFile,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));

      //predictRequest.fields['ext'] = mimeTypeData[1];
      predictRequest.files.add(file);

      try {
        final streamedResponse = await predictRequest.send();
        final predictResponse =
            await http.Response.fromStream(streamedResponse);

        if (predictResponse.statusCode == 200) {
          debugPrint("Successfully processed predict request");

          final Map<String, dynamic> responseData =
              json.decode(predictResponse.body);
          retCode = responseData['index'];
          debugPrint("Phrase ID: ${retCode.toString()}");
        } else {
          debugPrint(
              "Error while processing predict request: ${predictResponse.statusCode.toString()}");
        }
      } catch (e) {
        print(e);
      }
    }

    // if (File(_videoFile).existsSync()) {
    //   debugPrint("Processing video file $_videoFile");
    //   debugPrint("File length: ${File(_videoFile).lengthSync().toString()}");

    //   FirebaseVisionImage visionImage =
    //       FirebaseVisionImage.fromFilePath(_videoFile);

    //   if (visionImage != null) {
    //     debugPrint("Created vision image");

    //     final FaceDetectorOptions faceDetectorOptions = FaceDetectorOptions(
    //       enableTracking: true,
    //       enableLandmarks: true,
    //       enableContours: false,
    //       enableClassification: true,
    //       minFaceSize: 0.1,
    //       mode: FaceDetectorMode.accurate,
    //     );

    //     debugPrint("Created face detector option");

    //     final FaceDetector faceDetector =
    //         FirebaseVision.instance.faceDetector(faceDetectorOptions);

    //     debugPrint("Created face detector");
    //     // try {
    //     //   List<Face> faces = await faceDetector.processImage(visionImage);
    //     //   debugPrint("Face detector finished processing");
    //     // } on Exception catch (e) {
    //     //   print(e);
    //     // }
    //   } else {
    //     print("Failed to create vision image from file");
    //   }
    // } else {

    // DEBUG: emulate processing delay
    //await Future.delayed(Duration(seconds: 1));
    //}

    return retCode;
  }

  Future<void> _processVideo() async {
    // TODO - add processing

    //int phraseId = await analyzeVideo();
    // Debug
    int phraseId = -1;
    String query;

    _deleteMediaFiles();

    if (!_busy) return;

    if (phraseId >= 0) {
      await phraseBookFS.then((value) {
        query = (phraseId < value.length) ? value[phraseId].queries : null;
        setState(() {
          _newVoiceText =
              (phraseId < value.length) ? value[phraseId].text : null;
        });
      });
      if (query != null) {
        _notification = showSimpleNotification(
          Text(
            query,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: secondaryOrange400,
                fontWeight: FontWeight.bold,
                fontSize: 24),
          ),
          autoDismiss: false,
        );
        await _speak();
      }
    } else {
      await _showErrorDialog();
    }

    //await _onPhraseChange(_currentPhraseIdx);
    //await _speak();

    //OverlaySupportEntry.of(context).dismiss();

    setState(() {
      _busy = false;
      _notification?.dismiss();
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

  // ImageRotation rotationIntToImageRotation(int rotation) {
  //   switch (rotation) {
  //     case 90:
  //       return ImageRotation.rotation90;
  //     case 180:
  //       return ImageRotation.rotation180;
  //     case 270:
  //       return ImageRotation.rotation270;
  //     default:
  //       return ImageRotation.rotation0;
  //   }
  // }

  Size getImageSize() {
    return Size(
      _controller.value.previewSize.height,
      _controller.value.previewSize.width,
    );
  }

  Future<void> _showErrorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(
                Icons.error_outlined,
                color: Colors.red,
                size: 40,
              ),
              Text('Video Processing Error'),
            ],
          ),
          content: Text(
            'LipSpeak was unable to recognize the phrase. Please try again.',
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('DISMISS',
                  style: TextStyle(
                      fontSize: 18,
                      color: primaryIndigoDark,
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// draws rectangles when detects faces
  // Future<void> _frameFaces() async {
  //   imageSize = getImageSize();
  //   debugPrint("Image size: ${imageSize.toString()}");

  //   await _controller.startImageStream((image) async {
  //     if (_controller != null) {
  //       // if its currently busy, avoids overprocessing
  //       if (_detectingFaces) return;

  //       _detectingFaces = true;

  //       Future.delayed(const Duration(milliseconds: 300));
  //       try {
  //         List<Face> faces = await _frameFaceDetector.getFacesFromImage(image);

  //         if (faces != null) {
  //           if (faces.length > 0) {
  //             // preprocessing the image
  //             debugPrint("Face detected!");
  //             setState(() {
  //               faceDetected = faces[0];
  //             });

  //             // if (_saving) {
  //             //   _saving = false;
  //             //   _faceNetService.setCurrentPrediction(image, faceDetected);
  //             // }

  //           } else {
  //             setState(() {
  //               faceDetected = null;
  //             });
  //             //debugPrint("No faces found");
  //           }
  //         }

  //         _detectingFaces = false;
  //       } catch (e) {
  //         print(e);
  //         _detectingFaces = false;
  //       }
  //     }
  //   });
  // }
}
