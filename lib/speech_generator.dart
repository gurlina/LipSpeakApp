import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped }

class SpeechGenerator {
  FlutterTts flutterTts;

  final String language = "en-us";
  double volume;
  double pitch;
  double rate;

  TtsState ttsState = TtsState.stopped;

  SpeechGenerator({this.volume = 0.5, this.pitch = 1.0, this.rate = 0.5}) {
    initTts();
    configureTts(pitch: this.pitch, volume: this.volume, rate: this.rate);
  }

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;

  void initTts() {
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() {
      print("Playing");
      ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      print("Complete");
      ttsState = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      print("Cancel");
      ttsState = TtsState.stopped;
    });

    flutterTts.setErrorHandler((msg) {
      print("error: $msg");
      ttsState = TtsState.stopped;
    });
  }

  Future configureTts(
      {double volume = 0.5, double rate = 0.5, double pitch = 1.0}) async {
    flutterTts.setLanguage(this.language);
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
  }

  Future speakPhrase(String text) async {
    if (text != null) {
      if (text.isNotEmpty) {
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(text);
      }
    }
  }

  Future stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      ttsState = TtsState.stopped;
    }
  }
}
