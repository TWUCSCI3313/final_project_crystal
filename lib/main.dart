import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_flutter_project_hangman/utils/game.dart';
import 'package:final_flutter_project_hangman/widget/figure_image.dart';
import 'package:final_flutter_project_hangman/ui/pages/start_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      home: StartPage(toggleTheme: toggleTheme, isDarkMode: _isDarkMode),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color.fromARGB(255, 143, 210, 255),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue[700],
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.blueGrey,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A0057),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }
}

class HomeApp extends StatefulWidget {
  final String category;
  final Function toggleTheme;
  final bool isDarkMode;

  const HomeApp({
    super.key,
    required this.category,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  HomeAppState createState() => HomeAppState();
}

class HomeAppState extends State<HomeApp> {
  late String word;
  int _score = 0;
  int _secondsElapsed = 0;
  late Timer _timer;
  bool _gameWon = false;
  bool _gameOver = false;

  final List<String> alphabets = List.generate(
    26,
    (index) => String.fromCharCode(65 + index),
  );

  final Map<String, List<String>> categoryWords = {
    'animals': ['LION', 'TIGER', 'ELEPHANT', 'GIRAFFE', 'MONKEY'],
    'movies': ['AVATAR', 'TITANIC', 'INCEPTION', 'JURASSIC', 'FROZEN'],
    'sports': ['SOCCER', 'BASKETBALL', 'TENNIS', 'SWIMMING', 'BOXING'],
    'geography': ['MOUNTAIN', 'RIVER', 'OCEAN', 'DESERT', 'FOREST'],
    'food': ['PIZZA', 'BURGER', 'SUSHI', 'PASTA', 'SALAD'],
    'technology': ['COMPUTER', 'SMARTPHONE', 'TABLET', 'LAPTOP', 'CAMERA'],
    'default': ['FLUTTER', 'DART', 'ANDROID', 'IOS', 'WINDOWS'],
  };

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    Game.currentCategory = widget.category;
    word = _getRandomWord(widget.category);
    Game.tries = 0;
    Game.selectedChar = [];
    _secondsElapsed = 0;
    _score = 0;
    _gameWon = false;
    _gameOver = false;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gameWon && !_gameOver) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _getRandomWord(String category) {
    final words =
        categoryWords[category.toLowerCase()] ?? categoryWords['default']!;
    return words[Random().nextInt(words.length)].toLowerCase();
  }

  void _checkGameStatus() {
    final wordLetters = word.split('').toSet();
    final guessedLetters =
        Game.selectedChar.map((c) => c.toLowerCase()).toSet();
    final isWordGuessed = wordLetters.difference(guessedLetters).isEmpty;

    if (isWordGuessed) {
      _gameWon = true;
      _timer.cancel();
      _score = _calculateScore();
      _showGameResultDialog(true);
    } else if (Game.tries >= 6) {
      _gameOver = true;
      _timer.cancel();
      _showGameResultDialog(false);
    }
  }

  int _calculateScore() {
    final timeBonus = max(0, 300 - _secondsElapsed);
    final triesBonus = (6 - Game.tries) * 50;
    return timeBonus + triesBonus + 100;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hangman - ${widget.category.toUpperCase()}"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.toggleTheme(!widget.isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => StartPage(
                        toggleTheme: widget.toggleTheme,
                        isDarkMode: widget.isDarkMode,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Score: $_score",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Time: ${_secondsElapsed}s",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    figureImage(
                      Game.tries >= 0,
                      "assets/hang.png",
                      widget.isDarkMode,
                    ),
                    figureImage(
                      Game.tries >= 1,
                      "assets/head.png",
                      widget.isDarkMode,
                    ),
                    figureImage(
                      Game.tries >= 2,
                      "assets/body.png",
                      widget.isDarkMode,
                    ),
                    figureImage(
                      Game.tries >= 3,
                      "assets/ra.png",
                      widget.isDarkMode,
                    ),
                    figureImage(
                      Game.tries >= 4,
                      "assets/la.png",
                      widget.isDarkMode,
                    ),
                    figureImage(
                      Game.tries >= 5,
                      "assets/rl.png",
                      widget.isDarkMode,
                    ),
                    figureImage(
                      Game.tries >= 6,
                      "assets/ll.png",
                      widget.isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    word
                        .split('')
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Container(
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color:
                                        widget.isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                    width: 3,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Game.selectedChar.contains(e.toLowerCase())
                                    ? e.toUpperCase()
                                    : "",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              flex: 2,
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: alphabets.length,
                itemBuilder: (context, index) {
                  String letter = alphabets[index];
                  String lowerLetter = letter.toLowerCase();
                  bool alreadySelected = Game.selectedChar.contains(
                    lowerLetter,
                  );
                  return ElevatedButton(
                    onPressed:
                        alreadySelected || _gameWon || _gameOver
                            ? null
                            : () {
                              setState(() {
                                Game.selectedChar.add(lowerLetter);
                                if (!word.contains(lowerLetter)) {
                                  Game.tries++;
                                  _score = max(0, _score - 5);
                                } else {
                                  _score += 10;
                                }
                                _checkGameStatus();
                              });
                            },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          alreadySelected
                              ? Colors.grey[800]
                              : widget.isDarkMode
                              ? Colors.blueAccent[400]
                              : Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(letter),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameResultDialog(bool isWin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(isWin ? "You Won!" : "Game Over"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWin
                      ? "Congratulations! You guessed the word."
                      : "The word was: ${word.toUpperCase()}",
                ),
                const SizedBox(height: 16),
                Text("Final Score: $_score"),
                const SizedBox(height: 8),
                Text("Time taken: ${_secondsElapsed}s"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startNewGame();
                },
                child: const Text("Play Again"),
              ),
            ],
          ),
    );
  }
}
