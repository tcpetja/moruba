import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set to landscape mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(ErrorWidgetBuilder(child: const ProviderScope(child: MorubaApp())));
}

class ErrorWidgetBuilder extends StatelessWidget {
  final Widget child;

  const ErrorWidgetBuilder({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, widget) {
        ErrorWidget.builder = (errorDetails) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade900, Colors.purple.shade900],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 25),
                          Text(
                            'Game Error',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            errorDetails.exception.toString(),
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Restart Game'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        };
        return widget ?? child;
      },
      home: child,
    );
  }
}

// Game enums
enum Player { player1, player2 }

enum GameMode { singlePlayer, twoPlayer, onlineFriend, onlineRandom }

class MorubaApp extends StatelessWidget {
  const MorubaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moruba',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.amber,
          accentColor: Colors.blue,
        ).copyWith(secondary: Colors.blueAccent),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1.0, 1.0),
              ),
            ],
          ),
          titleLarge: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return FadeRouteBuilder(page: const HomeScreen());
          case '/mode':
            return SlideRouteBuilder(page: const ModeSelectionScreen());
          case '/offline':
            return SlideRouteBuilder(
              page: const OfflineModeScreen(),
              direction: AxisDirection.up,
            );
          case '/online':
            return SlideRouteBuilder(
              page: const OnlineModeScreen(),
              direction: AxisDirection.up,
            );
          case '/game':
            return SlideRouteBuilder(
              page: const GameScreen(),
              direction: AxisDirection.left,
            );
          case '/howtoplay':
            return SlideRouteBuilder(page: const HowToPlayScreen());
          default:
            return FadeRouteBuilder(page: const HomeScreen());
        }
      },
    );
  }
}

class FadeRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRouteBuilder({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      );
}

class SlideRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget page;
  final AxisDirection direction;

  SlideRouteBuilder({required this.page, this.direction = AxisDirection.right})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: _getBeginOffset(direction),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutQuart,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      );

  static Offset _getBeginOffset(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.up:
        return const Offset(0, 1);
      case AxisDirection.down:
        return const Offset(0, -1);
      case AxisDirection.left:
        return const Offset(1, 0);
      case AxisDirection.right:
        return const Offset(-1, 0);
    }
  }
}

final gameModeProvider = StateProvider<GameMode?>((ref) => null);

@immutable
class GameState {
  final List<int> board;
  final Player currentPlayer;
  final String? winner;
  final int? activePit;
  final Map<int, int> movingStones;
  final bool isPaused;
  final bool canCapture;
  final bool canBank;

  const GameState({
    required this.board,
    this.currentPlayer = Player.player1,
    this.winner,
    this.activePit,
    this.movingStones = const {},
    this.isPaused = false,
    this.canCapture = false,
    this.canBank = false,
  });

  bool get isGameOver => winner != null;

  GameState copyWith({
    List<int>? board,
    Player? currentPlayer,
    String? winner,
    int? activePit,
    Map<int, int>? movingStones,
    bool? isPaused,
    bool? canCapture,
    bool? canBank,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      activePit: activePit ?? this.activePit,
      movingStones: movingStones ?? this.movingStones,
      isPaused: isPaused ?? this.isPaused,
      canCapture: canCapture ?? this.canCapture,
      canBank: canBank ?? this.canBank,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier()
    : super(
        GameState(
          board: List.filled(24, 2) + [0, 0], // 24 pits + 2 banks
        ),
      );

  bool get isGameOver => state.winner != null;

  void makeMove(int pitIndex) {
    if (isGameOver ||
        state.movingStones.isNotEmpty ||
        !_isValidMove(pitIndex) ||
        state.isPaused) {
      return;
    }

    final board = List<int>.from(state.board);
    int stones = board[pitIndex];
    board[pitIndex] = 0;

    state = state.copyWith(
      activePit: pitIndex,
      movingStones: {pitIndex: stones},
      canCapture: false,
      canBank: false,
    );

    // Start the slower step-by-step distribution
    _distributeStonesStepByStep(board, pitIndex, stones);
  }

  void _distributeStonesStepByStep(
    List<int> board,
    int startIndex,
    int stones, {
    int? lastIndex,
  }) async {
    int currentIndex = startIndex;
    int stonesToMove = stones;
    final player = state.currentPlayer;

    // Create a copy of the board for intermediate states
    List<int> tempBoard = List<int>.from(board);

    // Clear moving stones at start of each distribution
    state = state.copyWith(movingStones: {});

    for (int i = 0; i < stonesToMove; i++) {
      if (state.isPaused || state.isGameOver) break;

      // Add a short delay between each stone movement
      await Future.delayed(const Duration(milliseconds: 300));

      currentIndex = _nextPit(currentIndex, player);
      tempBoard[currentIndex]++;

      // Update state to show the moving stone
      state = state.copyWith(
        board: List<int>.from(tempBoard),
        activePit: currentIndex,
        movingStones: {currentIndex: 1},
      );
    }

    // After distributing all stones, check for continuation
    if (tempBoard[currentIndex] > 1) {
      int newStones = tempBoard[currentIndex];
      tempBoard[currentIndex] = 0;

      // Add a slight pause before continuing
      await Future.delayed(const Duration(milliseconds: 500));

      _distributeStonesStepByStep(tempBoard, currentIndex, newStones);
    } else {
      // Finalize the move
      _finalizeMove(tempBoard, currentIndex);
    }
  }

  Future<void> _finalizeMove(List<int> board, int lastIndex) async {
    final player = state.currentPlayer;

    // Check for capture condition (landed in empty front row pit)
    bool captured = false;
    if (_isFrontRow(lastIndex, player) && board[lastIndex] == 1) {
      captured = _captureStones(board, lastIndex, player);
    }

    if (captured) {
      // Show the board state before capture
      state = state.copyWith(
        board: List<int>.from(board),
        activePit: lastIndex,
        movingStones: {},
      );

      await Future.delayed(const Duration(milliseconds: 800));

      // Highlight capture
      int col = _getColumn(lastIndex, player);
      int opponentFrontIndex = _getOpponentFrontIndex(col, player);
      int opponentBackIndex = _getOpponentBackIndex(col, player);

      // Show capture happening
      state = state.copyWith(
        activePit: null,
        movingStones: {
          opponentFrontIndex: board[opponentFrontIndex],
          opponentBackIndex: board[opponentBackIndex],
        },
      );

      await Future.delayed(const Duration(milliseconds: 800));

      // Clear captured pits
      board[opponentFrontIndex] = 0;
      board[opponentBackIndex] = 0;

      int bankIndex = player == Player.player1 ? 24 : 25;
      int capturedStones = board[bankIndex];

      // Show captured stones being moved to bank
      state = state.copyWith(
        board: List<int>.from(board),
        movingStones: {bankIndex: capturedStones},
      );

      await Future.delayed(const Duration(milliseconds: 800));

      // Final state with capture enabled
      state = state.copyWith(
        board: List<int>.from(board),
        movingStones: {},
        canCapture: true,
      );
    } else {
      // Check for game end
      final winner = _checkGameEnd(board);

      state = state.copyWith(
        board: board,
        activePit: null,
        movingStones: {},
        winner: winner,
      );

      // Switch turn if game not over
      if (winner == null) {
        _switchTurn();
      }
    }
  }

  int _nextPit(int current, Player player) {
    if (player == Player.player1) {
      // Player 1 (bottom) movement:
      // Back row: left to right (0→1→2→3→4→5)
      // Front row: right to left (11→10→9→8→7→6)
      if (current >= 0 && current <= 4) return current + 1;
      if (current == 5) return 11;
      if (current >= 7 && current <= 11) return current - 1;
      if (current == 6) return 0;
    } else {
      // Player 2 (top) movement:
      // Front row: left to right (18→19→20→21→22→23)
      // Back row: right to left (17→16→15→14→13→12)
      if (current >= 18 && current <= 22) return current + 1;
      if (current == 23) return 17;
      if (current >= 13 && current <= 17) return current - 1;
      if (current == 12) return 18;
    }
    return current; // Fallback
  }

  bool _isFrontRow(int index, Player player) {
    // Player 1's front row is pits 6-11
    if (player == Player.player1) {
      return index >= 6 && index <= 11;
    }
    // Player 2's front row is pits 18-23
    else {
      return index >= 18 && index <= 23;
    }
  }

  bool _captureStones(List<int> board, int lastIndex, Player player) {
    int col = _getColumn(lastIndex, player);
    int opponentFrontIndex = _getOpponentFrontIndex(col, player);
    int opponentBackIndex = _getOpponentBackIndex(col, player);

    // Only capture if opponent's front pit has at least 1 stone
    if (board[opponentFrontIndex] > 0) {
      int captured = board[opponentFrontIndex] + board[opponentBackIndex];
      int bankIndex = player == Player.player1 ? 24 : 25;
      board[bankIndex] += captured;
      return true;
    }
    return false;
  }

  int _getColumn(int index, Player player) {
    if (player == Player.player1) {
      return index - 6;
    } else {
      return index - 18;
    }
  }

  int _getOpponentFrontIndex(int col, Player player) {
    if (player == Player.player1) {
      return 18 + col;
    } else {
      return 6 + col;
    }
  }

  int _getOpponentBackIndex(int col, Player player) {
    if (player == Player.player1) {
      return 12 + col;
    } else {
      return col;
    }
  }

  void bankStones(int pitIndex) async {
    if (!state.canCapture || state.isPaused || state.isGameOver) return;

    final board = List<int>.from(state.board);
    int stones = board[pitIndex];
    board[pitIndex] = 0;

    int bankIndex = state.currentPlayer == Player.player1 ? 24 : 25;
    int currentBank = board[bankIndex];

    // Show stones being captured
    state = state.copyWith(movingStones: {pitIndex: stones});

    await Future.delayed(const Duration(milliseconds: 500));

    // Show stones moving to bank
    state = state.copyWith(movingStones: {bankIndex: stones});

    await Future.delayed(const Duration(milliseconds: 500));

    // Update the bank
    board[bankIndex] = currentBank + stones;

    // Check for game end
    final winner = _checkGameEnd(board);

    state = state.copyWith(
      board: board,
      canCapture: false,
      movingStones: {},
      winner: winner,
    );

    // Switch turn if game not over
    if (winner == null) {
      _switchTurn();
    }
  }

  void _switchTurn() {
    final nextPlayer = state.currentPlayer == Player.player1
        ? Player.player2
        : Player.player1;
    state = state.copyWith(currentPlayer: nextPlayer);
  }

  String? _checkGameEnd(List<int> board) {
    final player1Pits = board.sublist(0, 12).sum;
    final player2Pits = board.sublist(12, 24).sum;

    if (player1Pits == 0 || player2Pits == 0) {
      board[24] += player1Pits;
      board[25] += player2Pits;

      for (int i = 0; i < 24; i++) {
        board[i] = 0;
      }

      if (board[24] > board[25]) return "Player 1 Wins!";
      if (board[24] < board[25]) return "Player 2 Wins!";
      return "It's a Draw!";
    }
    return null;
  }

  bool _isValidMove(int pitIndex) {
    final isPlayer1 = state.currentPlayer == Player.player1;
    final validPlayer1Pits = pitIndex >= 0 && pitIndex <= 11;
    final validPlayer2Pits = pitIndex >= 12 && pitIndex <= 23;

    // Check if player has any pits with 2+ stones
    bool hasMultiStonePits = false;
    int start = isPlayer1 ? 0 : 12;
    int end = isPlayer1 ? 11 : 23;

    for (int i = start; i <= end; i++) {
      if (state.board[i] >= 2) {
        hasMultiStonePits = true;
        break;
      }
    }

    // If there are pits with 2+ stones, only allow those to be played
    if (hasMultiStonePits) {
      return state.board[pitIndex] >= 2 &&
          ((isPlayer1 && validPlayer1Pits) || (!isPlayer1 && validPlayer2Pits));
    }

    // Otherwise, allow any pit with stones
    return state.board[pitIndex] > 0 &&
        ((isPlayer1 && validPlayer1Pits) || (!isPlayer1 && validPlayer2Pits));
  }

  void resetGame() {
    state = GameState(board: List.filled(24, 2) + [0, 0]);
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber.shade400, Colors.blue.shade700],
              ),
            ),
          ),

          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.2),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxHeight < 600;
                return Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          DelayedAnimation(
                            delay: const Duration(milliseconds: 300),
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.amber.shade800,
                                    Colors.amber.shade300,
                                  ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                'MORUBA',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 48 : 58,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Text(
                            'The Ancient Board Game',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              color: Colors.white.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 30 : 60),

                          DelayedAnimation(
                            delay: const Duration(milliseconds: 600),
                            child: AnimatedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/mode'),
                              child: Container(
                                width: isSmallScreen ? 180 : 200,
                                height: isSmallScreen ? 50 : 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade700,
                                      Colors.amber.shade400,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.shade800.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'PLAY',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 30),

                          DelayedAnimation(
                            delay: const Duration(milliseconds: 900),
                            child: AnimatedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/howtoplay'),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 15 : 20,
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'HOW TO PLAY',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 30 : 50),

                          DelayedAnimation(
                            delay: const Duration(milliseconds: 1200),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Text(
                                '© 2025 MORUBA CLASSIC',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DelayedAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const DelayedAnimation({
    required this.child,
    required this.delay,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: duration,
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: child,
          );
        }
        return Container();
      },
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;

  const AnimatedButton({
    required this.child,
    required this.onPressed,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.purple.shade700],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedButton(
                onPressed: () => Navigator.pushNamed(context, '/offline'),
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.amber.shade400],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade800.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'OFFLINE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              AnimatedButton(
                onPressed: () => Navigator.pushNamed(context, '/online'),
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade800.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineModeScreen extends ConsumerWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade700, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedButton(
                onPressed: () {
                  ref.read(gameModeProvider.notifier).state =
                      GameMode.singlePlayer;
                  Navigator.pushNamed(context, '/game');
                },
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 30, color: Colors.white),
                      const SizedBox(width: 15),
                      const Text(
                        'SINGLE PLAYER',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              AnimatedButton(
                onPressed: () {
                  ref.read(gameModeProvider.notifier).state =
                      GameMode.twoPlayer;
                  Navigator.pushNamed(context, '/game');
                },
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 30, color: Colors.white),
                      const SizedBox(width: 15),
                      const Text(
                        'TWO PLAYERS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnlineModeScreen extends ConsumerWidget {
  const OnlineModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.purple.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedButton(
                onPressed: () {
                  ref.read(gameModeProvider.notifier).state =
                      GameMode.onlineFriend;
                  Navigator.pushNamed(context, '/game');
                },
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group, size: 30, color: Colors.white),
                      const SizedBox(width: 15),
                      const Text(
                        'PLAY WITH FRIEND',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              AnimatedButton(
                onPressed: () {
                  ref.read(gameModeProvider.notifier).state =
                      GameMode.onlineRandom;
                  Navigator.pushNamed(context, '/game');
                },
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shuffle, size: 30, color: Colors.white),
                      const SizedBox(width: 15),
                      const Text(
                        'RANDOM MATCH',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How To Play'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade400, Colors.blue.shade700],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              Center(
                child: Text(
                  'MORUBA RULES',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRuleItem(
                            context,
                            '1',
                            'Each player has two rows: front (closest to opponent) and back',
                          ),
                          _buildRuleItem(
                            context,
                            '2',
                            'All pits start with 2 stones',
                          ),
                          _buildRuleItem(
                            context,
                            '3',
                            'Players move stones counter-clockwise within their own rows:',
                          ),
                          _buildRuleItem(context, '', '  • Bottom player:'),
                          _buildRuleItem(
                            context,
                            '',
                            '      - Back row: left to right (0→1→2→3→4→5)',
                          ),
                          _buildRuleItem(
                            context,
                            '',
                            '      - Front row: right to left (11→10→9→8→7→6)',
                          ),
                          _buildRuleItem(context, '', '  • Top player:'),
                          _buildRuleItem(
                            context,
                            '',
                            '      - Front row: left to right (18→19→20→21→22→23)',
                          ),
                          _buildRuleItem(
                            context,
                            '',
                            '      - Back row: right to left (17→16→15→14→13→12)',
                          ),
                          _buildRuleItem(
                            context,
                            '4',
                            'You must move pits with 2+ stones first when available',
                          ),
                          _buildRuleItem(
                            context,
                            '5',
                            'When no 2+ stone pits remain, move from any pit with stones',
                          ),
                          _buildRuleItem(
                            context,
                            '6',
                            'Capture occurs when last stone lands in empty front-row pit',
                          ),
                          _buildRuleItem(
                            context,
                            '7',
                            'Capture takes stones from adjacent opponent pits in same column',
                          ),
                          _buildRuleItem(
                            context,
                            '8',
                            'After capture, choose ANY opponent pit to bank its stones',
                          ),
                          _buildRuleItem(
                            context,
                            '9',
                            'Game ends when one player has no stones left',
                          ),
                          _buildRuleItem(
                            context,
                            '10',
                            'Player with most stones in their bank wins',
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                'Tip: Plan moves to land in empty front-row pits!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverPanel extends StatefulWidget {
  final String winner;
  final int player1Score;
  final int player2Score;
  final bool isSinglePlayer;
  final VoidCallback onRestart;
  final VoidCallback onResume;
  final VoidCallback onModeChange;

  const _GameOverPanel({
    required this.winner,
    required this.player1Score,
    required this.player2Score,
    required this.isSinglePlayer,
    required this.onRestart,
    required this.onResume,
    required this.onModeChange,
  });

  @override
  State<_GameOverPanel> createState() => _GameOverPanelState();
}

class _GameOverPanelState extends State<_GameOverPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.height < 600;
    final containerSize = isSmall ? 80.0 : 120.0;
    final iconSize = isSmall ? 40.0 : 60.0;
    final buttonSize = isSmall ? 50.0 : 70.0;
    final buttonIconSize = isSmall ? 24.0 : 30.0;
    final buttonFontSize = isSmall ? 14.0 : 16.0;
    final titleFontSize = isSmall ? 28.0 : 36.0;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade800, Colors.purple.shade900],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.winner,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 5,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPlayerScore(true, containerSize, iconSize),
                          _buildPlayerScore(false, containerSize, iconSize),
                        ],
                      ),

                      const SizedBox(height: 50),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            Icons.refresh,
                            'Play Again',
                            Colors.amber,
                            widget.onRestart,
                            buttonSize,
                            buttonIconSize,
                            buttonFontSize,
                          ),
                          _buildActionButton(
                            Icons.home,
                            'Main Menu',
                            Colors.blue,
                            () => Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            ),
                            buttonSize,
                            buttonIconSize,
                            buttonFontSize,
                          ),
                          _buildActionButton(
                            Icons.swap_horiz,
                            'Change Mode',
                            Colors.green,
                            widget.onModeChange,
                            buttonSize,
                            buttonIconSize,
                            buttonFontSize,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerScore(bool isPlayer1, double size, double iconSize) {
    final isWinner =
        (isPlayer1 && widget.winner.contains('Player 1')) ||
        (!isPlayer1 && widget.winner.contains('Player 2'));

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPlayer1 ? Colors.amber : Colors.blue,
            border: Border.all(
              color: isWinner ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            isPlayer1
                ? Icons.person
                : (widget.isSinglePlayer ? Icons.computer : Icons.person),
            size: iconSize,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          isPlayer1
              ? 'Player 1'
              : (widget.isSinglePlayer ? 'Computer' : 'Player 2'),
          style: TextStyle(
            fontSize: iconSize * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${isPlayer1 ? widget.player1Score : widget.player2Score} stones',
          style: TextStyle(fontSize: iconSize * 0.4, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
    double size,
    double iconSize,
    double fontSize,
  ) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: iconSize, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PauseMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onModeChange;
  final VoidCallback onHome;

  const _PauseMenu({
    required this.onResume,
    required this.onRestart,
    required this.onModeChange,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.height < 600;
    final buttonSize = isSmall ? 60.0 : 80.0;
    final iconSize = isSmall ? 28.0 : 36.0;
    final fontSize = isSmall ? 16.0 : 18.0;
    final titleFontSize = isSmall ? 28.0 : 36.0;

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.all(isSmall ? 15 : 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade800, Colors.purple.shade900],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GAME PAUSED',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 5,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isSmall ? 30 : 60),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.play_arrow,
                        'Resume',
                        Colors.green,
                        onResume,
                        buttonSize,
                        iconSize,
                        fontSize,
                      ),
                      _buildActionButton(
                        Icons.refresh,
                        'Restart',
                        Colors.amber,
                        onRestart,
                        buttonSize,
                        iconSize,
                        fontSize,
                      ),
                    ],
                  ),

                  SizedBox(height: isSmall ? 20 : 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.swap_horiz,
                        'Change Mode',
                        Colors.blue,
                        onModeChange,
                        buttonSize,
                        iconSize,
                        fontSize,
                      ),
                      _buildActionButton(
                        Icons.home,
                        'Main Menu',
                        Colors.purple,
                        onHome,
                        buttonSize,
                        iconSize,
                        fontSize,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
    double size,
    double iconSize,
    double fontSize,
  ) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: iconSize, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  final Player player;
  final bool isActive;
  final int score;
  final bool isAI;

  const _PlayerInfo({
    required this.player,
    required this.isActive,
    required this.score,
    this.isAI = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.height < 600;
    final fontSize = isSmall ? 14.0 : 18.0;
    final iconSize = isSmall ? 24.0 : 32.0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 4 : 8,
        horizontal: isSmall ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? (player == Player.player1
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isActive
                ? (player == Player.player1 ? Colors.amber : Colors.blue)
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player 1 section
          if (player == Player.player1) ...[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 5 : 8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLAYER 1',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        '$score stones',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'YOUR TURN',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],

          // Player 2 section
          if (player == Player.player2) ...[
            if (isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAI ? 'THINKING...' : 'YOUR TURN',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isAI ? 'COMPUTER' : 'PLAYER 2',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        '$score stones',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.all(isSmall ? 5 : 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isAI ? Icons.computer : Icons.person,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BoardLayout extends ConsumerWidget {
  final GameState boardState;

  const _BoardLayout({required this.boardState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.watch(gameProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxHeight < 500;
        final storeWidth = isSmall
            ? constraints.maxWidth * 0.12
            : constraints.maxWidth * 0.14;

        final pitSize = math
            .min(
              constraints.maxWidth * (isSmall ? 0.12 : 0.14),
              constraints.maxHeight * 0.25,
            )
            .clamp(isSmall ? 40.0 : 50.0, 90.0);

        return Row(
          children: [
            // Player2 store
            _StoreWidget(
              stones: boardState.board[25],
              width: storeWidth,
              height: constraints.maxHeight,
              player: Player.player2,
            ),

            Expanded(
              child: Column(
                children: [
                  // Player2 back row (12-17)
                  SizedBox(
                    height: constraints.maxHeight * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        final pitIndex = 12 + index;
                        return _PitWidget(
                          stones: boardState.board[pitIndex],
                          pitIndex: pitIndex,
                          size: pitSize,
                          player: Player.player2,
                          isBackRow: true,
                          onTap: () {
                            if (state.canCapture) {
                              notifier.bankStones(pitIndex);
                            }
                          },
                        );
                      }),
                    ),
                  ),

                  // Player2 front row (18-23)
                  SizedBox(
                    height: constraints.maxHeight * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        final pitIndex = 18 + index;
                        return _PitWidget(
                          stones: boardState.board[pitIndex],
                          pitIndex: pitIndex,
                          size: pitSize,
                          player: Player.player2,
                          isFrontRow: true,
                          onTap: () {
                            if (state.canCapture) {
                              notifier.bankStones(pitIndex);
                            }
                          },
                        );
                      }),
                    ),
                  ),

                  // Player1 front row (6-11)
                  SizedBox(
                    height: constraints.maxHeight * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        final pitIndex = 6 + index;
                        return _PitWidget(
                          stones: boardState.board[pitIndex],
                          pitIndex: pitIndex,
                          size: pitSize,
                          player: Player.player1,
                          isFrontRow: true,
                          onTap: () {
                            if (state.canCapture) {
                              notifier.bankStones(pitIndex);
                            }
                          },
                        );
                      }),
                    ),
                  ),

                  // Player1 back row (0-5)
                  SizedBox(
                    height: constraints.maxHeight * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return _PitWidget(
                          stones: boardState.board[index],
                          pitIndex: index,
                          size: pitSize,
                          player: Player.player1,
                          isBackRow: true,
                          onTap: () {
                            if (state.canCapture) {
                              notifier.bankStones(index);
                            }
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // Player1 store
            _StoreWidget(
              stones: boardState.board[24],
              width: storeWidth,
              height: constraints.maxHeight,
              player: Player.player1,
            ),
          ],
        );
      },
    );
  }
}

class _PitWidget extends ConsumerWidget {
  final int stones;
  final int pitIndex;
  final double size;
  final Player player;
  final bool isBackRow;
  final bool isFrontRow;
  final VoidCallback onTap;

  const _PitWidget({
    required this.stones,
    required this.pitIndex,
    required this.size,
    required this.player,
    this.isBackRow = false,
    this.isFrontRow = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.watch(gameProvider);
    final isActive = state.activePit == pitIndex;
    final isValidMove = notifier._isValidMove(pitIndex);
    final isCurrentPlayer =
        (player == Player.player1 && state.currentPlayer == Player.player1) ||
        (player == Player.player2 && state.currentPlayer == Player.player2);

    return GestureDetector(
      onTap: () {
        if (isValidMove &&
            isCurrentPlayer &&
            !state.isPaused &&
            !state.canCapture) {
          notifier.makeMove(pitIndex);
        } else if (state.canCapture) {
          onTap();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _getPitColor(),
          borderRadius: BorderRadius.circular(size / 2),
          border: isActive
              ? Border.all(color: Colors.red, width: 3)
              : Border.all(
                  color: _getBorderColor(isValidMove, isCurrentPlayer, state),
                  width: 2,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$stones',
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
            if (stones > 0)
              ...List.generate(
                math.min(stones, 12), // Limit stones for small pits
                (index) =>
                    _StoneWidget(index: index, total: stones, size: size),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPitColor() {
    if (isFrontRow) {
      return player == Player.player1
          ? Colors.amber.shade400
          : Colors.blue.shade400;
    } else if (isBackRow) {
      return player == Player.player1
          ? Colors.amber.shade300
          : Colors.blue.shade300;
    }
    return player == Player.player1
        ? Colors.amber.shade200
        : Colors.blue.shade200;
  }

  Color _getBorderColor(
    bool isValidMove,
    bool isCurrentPlayer,
    GameState state,
  ) {
    if (state.canCapture) {
      return Colors.green;
    }
    return isValidMove && isCurrentPlayer ? Colors.white : Colors.grey;
  }
}

class _StoneWidget extends StatefulWidget {
  final int index;
  final int total;
  final double size;

  const _StoneWidget({
    required this.index,
    required this.total,
    required this.size,
  });

  @override
  State<_StoneWidget> createState() => _StoneWidgetState();
}

class _StoneWidgetState extends State<_StoneWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500 + widget.index * 100),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    // Adjust stone distribution based on total stones
    final maxStones = widget.total > 8 ? 8 : widget.total;
    final angle = 2 * math.pi * widget.index / math.max(maxStones, 1);
    final radius = widget.size / 3;

    final offset = Offset(
      widget.size / 2 + radius * math.cos(angle),
      widget.size / 2 + radius * math.sin(angle),
    );

    return Positioned(
      left: offset.dx - widget.size / 10,
      top: offset.dy - widget.size / 10,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: Container(
          width: widget.size / 5,
          height: widget.size / 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.brown.shade300, Colors.brown.shade700],
              stops: const [0.4, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _StoreWidget extends StatelessWidget {
  final int stones;
  final double width;
  final double height;
  final Player player;

  const _StoreWidget({
    required this.stones,
    required this.width,
    required this.height,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height * 0.7,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: player == Player.player1
              ? [Colors.amber.shade700, Colors.amber.shade400]
              : [Colors.blue.shade700, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$stones',
          style: TextStyle(
            fontSize: width * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameMode = ref.watch(gameModeProvider);
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    if (gameMode == GameMode.singlePlayer &&
        state.currentPlayer == Player.player2 &&
        !state.isGameOver &&
        state.movingStones.isEmpty &&
        !state.isPaused) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _makeAIMove(notifier, state);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.amber.shade200, Colors.blue.shade300],
              ),
            ),
          ),

          // Responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate heights with padding to prevent overflow
              final availableHeight = constraints.maxHeight;
              final playerInfoHeight = math.min(availableHeight * 0.12, 60.0);
              final boardHeight = availableHeight - 2 * playerInfoHeight;

              return Column(
                children: [
                  // Top player info
                  SizedBox(
                    height: playerInfoHeight,
                    child: gameMode == GameMode.singlePlayer
                        ? _PlayerInfo(
                            player: Player.player2,
                            isActive: state.currentPlayer == Player.player2,
                            score: state.board[25],
                            isAI: true,
                          )
                        : _PlayerInfo(
                            player: Player.player2,
                            isActive: state.currentPlayer == Player.player2,
                            score: state.board[25],
                          ),
                  ),

                  // Game board
                  SizedBox(
                    height: boardHeight,
                    child: _BoardLayout(boardState: state),
                  ),

                  // Bottom player info
                  SizedBox(
                    height: playerInfoHeight,
                    child: _PlayerInfo(
                      player: Player.player1,
                      isActive: state.currentPlayer == Player.player1,
                      score: state.board[24],
                    ),
                  ),
                ],
              );
            },
          ),

          // Pause button
          Positioned(
            top: 10,
            left: 10,
            child: AnimatedButton(
              onPressed: () => notifier.togglePause(),
              child: Icon(
                Icons.pause,
                color: Colors.white,
                size: 30,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
              ),
            ),
          ),

          // Capture/banking indicator
          if (state.canCapture || state.canBank)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.canCapture
                        ? 'Capture available! Tap opponent pits'
                        : 'Bank stones: Tap an opponent pit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Full-screen game over panel
          if (state.winner != null)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: _GameOverPanel(
                winner: state.winner!,
                player1Score: state.board[24],
                player2Score: state.board[25],
                isSinglePlayer: gameMode == GameMode.singlePlayer,
                onRestart: notifier.resetGame,
                onResume: () {}, // Not needed for game over
                onModeChange: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.settings.name == '/mode',
                  );
                },
              ),
            ),

          // Pause menu
          if (state.isPaused && state.winner == null)
            _PauseMenu(
              onResume: () => notifier.togglePause(),
              onRestart: notifier.resetGame,
              onModeChange: () {
                Navigator.popUntil(
                  context,
                  (route) => route.settings.name == '/mode',
                );
              },
              onHome: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
        ],
      ),
    );
  }

  void _makeAIMove(GameNotifier notifier, GameState state) {
    // First, look for pits with 2+ stones
    List<int> validPits = [];
    for (int i = 12; i <= 23; i++) {
      if (state.board[i] >= 2) {
        validPits.add(i);
      }
    }

    // If no 2+ stone pits, look for any pits with stones
    if (validPits.isEmpty) {
      for (int i = 12; i <= 23; i++) {
        if (state.board[i] > 0) {
          validPits.add(i);
        }
      }
    }

    if (validPits.isNotEmpty) {
      final randomIndex = math.Random().nextInt(validPits.length);
      notifier.makeMove(validPits[randomIndex]);
    }
  }
}
