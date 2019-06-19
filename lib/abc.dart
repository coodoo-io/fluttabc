import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'library.dart';

class ABCPage extends StatefulWidget {
  ABCPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ABCPageState createState() => _ABCPageState();
}

class _ABCPageState extends State<ABCPage> {
  bool _alphabet = true;
  String _text = '';
  List<String> _characters = Library.letters;
  List<String> _words = Library.words;
  Map<String, String> languageNames = Library.languageNames;

  FlutterTts flutterTts;
  List<String> languages = List<String>();
  String language = 'de-DE';

  @override
  initState() {
    super.initState();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage(language);
    flutterTts.setSpeechRate(1.0);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);

    if (Platform.isAndroid) {
      flutterTts.ttsInitHandler(() {
        _getLanguages();
      });
    } else if (Platform.isIOS) {
      _getLanguages();
    }
  }

  Future _getLanguages() async {
    dynamic sysLanguages = await flutterTts.getLanguages;
    if (sysLanguages != null) {
      for (String lang in sysLanguages) {
        languages.add(lang);
      }
      languages.sort();
      setState(() => languages);
    }
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  String getLanguageName(String language) {
    /// 'de-DE' --> 'de' als Key zum Map
    var name = Library.languageNames[language.substring(0, 2)];
    if (name == null) {
      return language;
    }
    return name;
  }

  AssetImage getLanguageFlagAssetImage(String language) {
    /// 'de-AT' --> 'AT' --> at.png
    var name = language.substring(language.length - 2, language.length);
    if (name != null) {
      return new AssetImage(
          'assets/images/flags/' + name.toLowerCase() + '.png');
    }
    return new AssetImage('assets/images/logo-512.png');
  }

  void changeLanguage(String selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language);
      _readText();
    });
  }

  void _toggleAlphabet() {
    setState(() {
      _alphabet = !_alphabet;
      if (_alphabet) {
        _read('Buchstaben');
        _characters = Library.letters;
        _words = Library.words;
      } else {
        _read('Zahlen');
        _characters = Library.digits;
        _words = Library.numbers;
      }
    });
  }

  void _appendLetter(String character) {
    setState(() {
      /// Buchstabe bei Eingabe ausspechen!
      switch (character) {
        case '→':
          character = ' ';
          _read('Neues Wort');
          break;
        case 'Ä':
          _read('äh');
          break;
        case 'Ö':
          _read('öh');
          break;
        case 'Ü':
          _read('üh');
          break;
        default:
          _read(character);
      }
      _text += character;
    });
  }

  void _clear() {
    _read('Von Vorne!');
    setState(() {
      _text = '';
    });
  }

  void _backspace() {
    _read('Zurück!');
    setState(() {
      if (_text.length > 0) {
        _text = _text.substring(0, _text.length - 1);
      }
    });
  }

  void _randomText() {
    setState(() {
      var random = new Random();
      _text = _words[random.nextInt(_words.length)];
      _read(_text);
    });
  }

  void _readText() {
    setState(() {
      _read(_text);
    });
  }

  Future _read(String text) async {
    // Wenn noch am Reden, dann Klappe halten!
    await flutterTts.stop();
    if (text != null && text.isNotEmpty) {
      /// Als Kleinbuchstaben aussprechen lassen, da sonst immer "Großbuchstabe X" statt nur "X" gesagt wird...
      await flutterTts.speak(text.toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(context),
      body: Center(
        child: Container(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).orientation == Orientation.portrait
                  ? 100 // MediaQuery.of(context).size.height / 7
                  : 0),
          child: Column(
            children: [
              textButtons(),
              textDisplay(context),
              lettersInput(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _readText,
        tooltip: 'Text anhören',
        child: Icon(Icons.play_arrow),
      ),
    );
  }

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Das Alphabet sehen und hören'),
            decoration: BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                image: AssetImage('assets/images/logo-512.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          languages != null // Warten auf Liste!
              ? Column(
                  children: <Widget>[
                    for (var lang in languages)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: getLanguageFlagAssetImage(lang),
                        ),
                        selected: lang == language,
                        title: Text(
                          getLanguageName(lang),
                        ),
                        subtitle: Text(lang),
                        onTap: () {
                          // Sparche gewählt
                          changeLanguage(lang); // Text lesen
                          Navigator.of(context).pop(); // Drawer schließen
                        },
                      ),
                  ],
                )
              : new Container(),
        ],
      ),
    );
  }

  Row textButtons() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: IconButton(
            icon: Icon(Icons.clear),
            color: Colors.blueAccent,
            splashColor: Colors.blue,
            tooltip: 'Von Vorne!',
            onPressed: _clear,
          ),
        ),
        Expanded(
          flex: 1,
          child: IconButton(
            icon: Icon(Icons.loop),
            color: Colors.blueAccent,
            splashColor: Colors.blue,
            tooltip: _alphabet ? 'Zufällige Zahl' : 'Zufälliges Wort',
            onPressed: _randomText,
          ),
        ),
        Expanded(
          flex: 1,
          child: IconButton(
            icon: _alphabet ? Icon(Icons.plus_one) : Icon(Icons.spellcheck),
            color: Colors.blueAccent,
            splashColor: Colors.blue,
            tooltip: _alphabet ? 'Zahlen' : 'Buchstaben',
            onPressed: _toggleAlphabet,
          ),
        ),
        Expanded(
          flex: 1,
          child: IconButton(
            icon: Icon(Icons.undo),
            color: Colors.blueAccent,
            splashColor: Colors.blue,
            tooltip: 'Eins zurück!',
            onPressed: _backspace,
          ),
        ),
      ],
    );
  }

  Row textDisplay(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: _readText,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: _alphabet
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '$_text',
                      style: Theme.of(context).textTheme.display1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Expanded lettersInput(BuildContext context) {
    return Expanded(
      child: GridView(
        padding: const EdgeInsets.all(20.0),
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? 6
                    : _alphabet ? 10 : 12),
        children: <Widget>[
          for (var letter in _characters)
            FlatButton(
              onPressed: () {
                _appendLetter(letter);
              },
              child: Column(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(
                    letter,
                    style: Theme.of(context).textTheme.display1,
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
