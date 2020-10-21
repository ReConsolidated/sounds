import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

// notatka: dzwieki od C0 do C4 - od 12 do 60
// 12 dzwiekow na oktawe
const Intervals = {
  1: {"Sekunda mała", "sm"},
  2: {"Sekunda wielka", "sw"},
  3: {"Tercja mała", "tm"},
  4: {"Tercja wielka", "tw"},
  5: {"Kwarta czysta", "kr"},
  6: {"Tryton", "tr"},
  7: {"Kwinta czysta", "kn"},
  8: {"Seksta mała", "skm"},
  9: {"Seksta wielka", "skw"},
  10: {"Septyma mała", "spm"},
  11: {"Septyma wielka", "spw"},
  12: {"Oktawa", "ok"},
};

enum QuizState { UNDONE, CORRECT, WRONG }

void main() {
  _setTargetPlatformForDesktop();
  return runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    load(_value);
    inputFocusNode.addListener(() {
      setState(() {});
    });
    _setupQuiz();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    answerController.dispose();
    super.dispose();
  }

  final _flutterMidi = FlutterMidi();
  final answerController = TextEditingController();
  final inputFocusNode = FocusNode();

  int _currentNote = 0;
  int _currentInterval = 0;
  int _currentQuiz = 0;
  String _value = "assets/Piano.sf2";
  var _quiz = new List<QuizState>(5);

  void load(String asset) async {
    print("Loading File...");
    _flutterMidi.unmute();
    ByteData _byte = await rootBundle.load(asset);
    //assets/sf2/SmallTimGM6mb.sf2
    //assets/sf2/Piano.SF2
    _flutterMidi.prepare(sf2: _byte, name: _value.replaceAll("assets/", ""));
  }

  Future<void> _delay(int milliseconds) async {
    await new Future.delayed(new Duration(milliseconds: milliseconds));
  }

  int getRandomInterval() {
    var rng = new Random();
    if (rng.nextBool()) {
      return (rng.nextInt(12) + 1) * -1;
    }
    return rng.nextInt(12) + 1;
  }

  int getRandomNote() {
    var rng = new Random();
    return rng.nextInt(48) + 12;
  }

  void _setupQuiz() {
    for (int i = 0; i < 5; i++) {
      _quiz[i] = QuizState.UNDONE;
    }
    _currentQuiz = 0;
    do {
      _currentNote = getRandomNote();
      _currentInterval = getRandomInterval();
    } while (_currentNote + _currentInterval < 12 ||
        _currentNote + _currentInterval > 60);
    setState(() {});
  }

  void _playInterval() async {
    if (_currentNote == 0 || _currentInterval == 0 || _currentQuiz > 4) return;
    inputFocusNode.unfocus();
    _flutterMidi.playMidiNote(midi: _currentNote);
    await _delay(500);
    _flutterMidi.stopMidiNote(midi: _currentNote);
    _flutterMidi.playMidiNote(midi: _currentNote + _currentInterval);
    await _delay(500);
    _flutterMidi.stopMidiNote(midi: _currentNote + _currentInterval);

    print(_currentInterval);
  }

  void _checkAnswer() {
    if (_currentQuiz > 4 || _currentNote == 0) return;
    inputFocusNode.unfocus();

    bool isCorrect = false;
    Intervals[_currentInterval.abs()].forEach((_name) {
      if (!isCorrect)
        isCorrect =
            (answerController.text.toLowerCase() == _name.toLowerCase());
    });

    answerController.clear();
    if (isCorrect) {
      print("Correct");
      _flutterMidi.playMidiNote(midi: 48);
      _delay(200).then((_) {
        _flutterMidi.stopMidiNote(midi: 48);
      });
      _quiz[_currentQuiz] = QuizState.CORRECT;
    } else {
      print("Wrong");
      _flutterMidi.playMidiNote(midi: 19);
      _delay(200).then((_) {
        _flutterMidi.stopMidiNote(midi: 19);
      });
      _quiz[_currentQuiz] = QuizState.WRONG;
    }
    setState(() {});
    _currentNote = 0;
    _delay(3000).then((_) {
      _currentQuiz++;
      do {
        _currentNote = getRandomNote();
        _currentInterval = getRandomInterval();
      } while (_currentNote + _currentInterval < 12 ||
          _currentNote + _currentInterval > 60);
      _playInterval();
      setState(() {});
    });
  }

  AssetImage _checkBoxImage(int index) {
    switch (_quiz[index]) {
      case QuizState.UNDONE:
        return AssetImage("./assets/images/checkbox-undone.png");
        break;
      case QuizState.CORRECT:
        return AssetImage("./assets/images/checkbox-correct.png");
        break;
      case QuizState.WRONG:
        return AssetImage("./assets/images/checkbox-wrong.png");
        break;
    }
    return AssetImage("./assets/images/checkbox-wrong.png");
  }

  Text _outputText() {
    if (_currentQuiz > 4 || _currentInterval == 0)
      return Text(
        "...",
        style: TextStyle(color: Colors.black, fontSize: 30),
      );
    switch (_quiz[_currentQuiz]) {
      case QuizState.UNDONE:
        return Text(
          "...",
          style: TextStyle(color: Colors.black, fontSize: 30),
        );
        break;

      case QuizState.CORRECT:
        return Text(
          Intervals[_currentInterval.abs()].first,
          style: TextStyle(color: Colors.green, fontSize: 30),
        );
        break;

      case QuizState.WRONG:
        return Text(
          Intervals[_currentInterval.abs()].first,
          style: TextStyle(color: Colors.red, fontSize: 30),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Rozpoznawanie interwałów'),
            actions: [
              IconButton(
                icon: Icon(Icons.repeat_rounded),
                onPressed: _setupQuiz,
              )
            ],
          ),
          body: Container(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                      margin: EdgeInsets.all(15),
                      height: 40,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Image(
                              image: _checkBoxImage(0),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Image(
                              image: _checkBoxImage(1),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Image(
                              image: _checkBoxImage(2),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Image(
                              image: _checkBoxImage(3),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Image(
                              image: _checkBoxImage(4),
                            ),
                          ),
                        ],
                      )),
                  Container(
                    margin: EdgeInsets.all(20),
                    child: _outputText(),
                  ),
                  Container(
                    margin: EdgeInsets.all(20),
                    height: 200,
                    child: MaterialButton(
                      child: Image(image: AssetImage("assets/images/note.png")),
                      enableFeedback: false,
                      onPressed: () {
                        _playInterval();
                      },
                    ),
                  ),
                  Container(
                    width: 200,
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: answerController,
                      focusNode: inputFocusNode,
                      decoration: new InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.grey, width: 1.0),
                        ),
                        hintText:
                            inputFocusNode.hasFocus ? "" : "np. septyma mała",
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(20),
                    child: RaisedButton(
                      child: Text("Sprawdź"),
                      onPressed: _checkAnswer,
                    ),
                  )
                ],
              ),
            ),
          )),
    );
  }
}

/// If the current platform is desktop, override the default platform to
/// a supported platform (iOS for macOS, Android for Linux and Windows).
/// Otherwise, do nothing.

void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (Platform.isMacOS) {
    targetPlatform = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    targetPlatform = TargetPlatform.android;
  }
  if (targetPlatform != null) {
    debugDefaultTargetPlatformOverride = targetPlatform;
  }
}
