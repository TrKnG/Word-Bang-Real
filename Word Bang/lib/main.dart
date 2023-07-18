import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'word_provider.dart';

final Map<String, int> letterPoints = {
  'a': 1, 'b': 3, 'c': 4, 'ç': 4, 'd': 3, 'e': 1, 'f': 7, 'g': 5, 'ğ': 8, 'h': 5,
  'ı': 2, 'i': 1, 'j': 10, 'k': 1, 'l': 1, 'm': 2, 'n': 1, 'o': 2, 'ö': 7, 'p': 5,
  'r': 1, 's': 2, 'ş': 4, 't': 1, 'u': 2, 'ü': 3, 'v': 7, 'y': 3, 'z': 4
};


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final WordProvider wordProvider = WordProvider();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<List<String>>(
        future: wordProvider.loadWordList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MyHomePage(wordList: snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<String> wordList;
  final Set<String> wordSet;

  MyHomePage({required this.wordList})
      : wordSet = wordList.map((word) => word.toLowerCase()).toSet();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<String> gridItems = List.generate(80, (index) => '');
  List<bool> selected = List.generate(80, (index) => false);
  List<String> selectedLetters = [];
  final List<String> vowels = ['a', 'e', 'i', 'o', 'u', 'ö', 'ü'];
  final List<String> consonants = ['b','c','ç','d','f','g','ğ','h','j','k','l','m','n','p','r','s','ş','t','v','y','z'];
  int totalPoints = 0;

  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _wordController = TextEditingController();
  Set<String> _wordSet = {};
  Timer? _moveLetterTimer;
  Timer? _dropLetterTimer;

  List<_DropData> _dropDataList = [];

  bool isValidWord(String word) {
    return _wordSet.contains(word.toLowerCase());
  }

  int calculateWordPoints(String word) {
    int wordPoints = 0;

    for (int i = 0; i < word.length; i++) {
      String letter = word[i].toLowerCase();
      wordPoints += letterPoints[letter] ?? 0;
    }

    return wordPoints;
  }

  @override
  void initState() {
    super.initState();
    fillInitialRows();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _wordSet = Set<String>.from(widget.wordSet);
    _animationController.forward();
    startMoveLetterTimer();
    startDropLetterTimer();
  }


  @override
  void dispose() {
    _animationController.dispose();
    _wordController.dispose();
    _moveLetterTimer?.cancel();
    _dropLetterTimer?.cancel();
    _dropDataList.forEach((dropData) => dropData.controller.dispose());
    super.dispose();
  }


  void fillInitialRows() {
    for (int i = 56; i < 80; i++) {
      gridItems[i] = getRandomLetter();
    }
  }

  String getRandomLetter() {
    final random = Random();
    bool isVowel = random.nextDouble() < 0.3;
    int index;

    if (isVowel) {
      index = random.nextInt(vowels.length);
      return vowels[index];
    } else {
      index = random.nextInt(consonants.length);
      return consonants[index];
    }
  }
  void onLetterTap(int index) {
    setState(() {
      if (selected[index]) {
        selected[index] = false;
        selectedLetters.remove(gridItems[index]);
      } else {
        selected[index] = true;
        selectedLetters.add(gridItems[index]);
      }
      _wordController.text = selectedLetters.join();
    });
  }

  void startMoveLetterTimer() {
    _moveLetterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        moveLettersDown();
      });
    });
  }

  void moveLettersDown() {
    for (int col = 0; col < 8; col++) {
      for (int row = 6; row >= 0; row--) {
        int index = col + row * 8;
        if (gridItems[index] != '' && gridItems[index + 8] == '') {
          gridItems[index + 8] = gridItems[index];
          gridItems[index] = '';
        }
      }
    }
  }


  bool _isDropping = false;

  void startDropLetterTimer() {
    _dropLetterTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isDropping) {
        setState(() {
          dropRandomLetter();
        });
      }
    });
  }

  void dropRandomLetter() {
    _isDropping = true;
    int randomColumn = Random().nextInt(8);

    for (int i = 0; i < 56; i += 8) {
      if (gridItems[randomColumn + i] == '') {
        gridItems[randomColumn + i] = getRandomLetter();
        AnimationController dropController = AnimationController(
          duration: const Duration(seconds: 3),
          vsync: this,
        );

        Animation<double> dropAnimation = Tween<double>(begin: -1, end: 0).animate(dropController);

        dropController.forward().then((_) {
          _dropDataList.removeWhere((dropData) => dropData.controller == dropController);
          dropController.dispose();
          _isDropping = false;
        });

        _dropDataList.add(_DropData(controller: dropController, animation: dropAnimation, index: randomColumn + i));

        break;
      } else {
        int nextIndex = randomColumn + i + 8;
        if (nextIndex < 56) {
          gridItems[nextIndex] = gridItems[randomColumn + i];
          gridItems[randomColumn + i] = '';
        } else {
          _isDropping = false;
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    _animation = Tween<double>(begin: -MediaQuery.of(context).size.height, end: 0).animate(_animationController);

    return Scaffold(
        appBar: AppBar(
          title: Text('Yazlab Kelime Oyunu'),
        ),
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: InputDecoration(
                      hintText: 'Kelime oluşturun',
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Oluşturulan Kelime: ${_wordController.text}',
              style: TextStyle(fontSize: 20),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  itemCount: 80,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (BuildContext context, Widget? child) {
                            return Transform.translate(
                              offset: Offset(0, index >= 56 ? _animation.value : 0),
                              child: GestureDetector(
                                onTap: () => onLetterTap(index),
                                child: Card(
                                  color: selected[index] ? Colors.purple : null,
                                  child: Center(
                                      child: Text(
                                        gridItems[index],
                                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      )),
                                ),
                              ),
                            );
                          },
                        ),
                        ..._dropDataList.map((dropData) {
                          return AnimatedBuilder(
                            animation: dropData.controller,
                            builder: (BuildContext context, Widget? child) {
                              return Transform.translate(
                                offset: Offset(0, index == dropData.index ? dropData.animation.value * 56.0 : 0),
                                child: GestureDetector(
                                  onTap: () => onLetterTap(index),
                                  child: Card(
                                    color: selected[index] ? Colors.purple : null,
                                    child: Center(
                                        child: Text(
                                          gridItems[index],
                                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                        )),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    String word = _wordController.text;
                    if (isValidWord(word)) {
                      int wordPoints = calculateWordPoints(word);
                      setState(() {
                        totalPoints += wordPoints;
                      });
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Tebrikler!'),
                            content: Text('Geçerli bir kelime oluşturdunuz: $word. Bu kelime $wordPoints puan değerinde. Toplam puanınız: $totalPoints.'),
                            actions: [
                              TextButton(
                                child: Text('Tamam'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Üzgünüm!'),
                            content: Text('Geçerli bir kelime oluşturamadınız: $word'),
                            actions: [
                              TextButton(
                                child: Text('Tamam'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text('Kelimeyi Kontrol Et'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedLetters.clear();
                      for (int i = 0; i < selected.length; i++) {
                        selected[i] = false;
                      }
                      _wordController.text = '';
                    });
                  },
                  child: Icon(Icons.clear, color: Colors.red),
                ),
              ],
            )
          ],
        )
    );
  }
}

class _DropData {
  final AnimationController controller;
  final Animation<double> animation;
  final int index;

  _DropData({required this.controller, required this.animation, required this.index});
}
