import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'domain/player.dart';
import 'state/game_state.dart';
import 'state/game_notifier.dart';
import 'presentation/moruba_board_game.dart';
import 'presentation/how_to_play_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(ErrorWidgetBuilder(child: const ProviderScope(child: MorubaApp())));
}

class ErrorWidgetBuilder extends StatelessWidget {
  final Widget child;
  const ErrorWidgetBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, widget) {
        ErrorWidget.builder = (errorDetails) {
          return Scaffold(
            body: Center(
              child: Text(
                'Game Error\n${errorDetails.exception}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
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

enum GameMode { singlePlayer, twoPlayer, onlineFriend, onlineRandom }
enum FirstPlayerChoice { player1, player2, random }

final gameModeProvider = StateProvider<GameMode?>((ref) => null);
final boardSizeProvider = StateProvider<int>((ref) => 12); 
final aiDifficultyProvider = StateProvider<AIDifficulty>((ref) => AIDifficulty.expert);

class MorubaApp extends StatelessWidget {
  const MorubaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moruba',
      theme: ThemeData(primarySwatch: Colors.amber, useMaterial3: true),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/': return FadeRouteBuilder(page: const HomeScreen());
          case '/mode': return SlideRouteBuilder(page: const ModeSelectionScreen());
          case '/offline': return SlideRouteBuilder(page: const OfflineModeScreen(), direction: AxisDirection.up);
          case '/online': return SlideRouteBuilder(page: const OnlineModeScreen(), direction: AxisDirection.up);
          case '/game': return SlideRouteBuilder(page: const GameScreen(), direction: AxisDirection.left);
          case '/howtoplay': return SlideRouteBuilder(page: const HowToPlayScreen());
          default: return FadeRouteBuilder(page: const HomeScreen());
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
          return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut), child: child);
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
            position: Tween<Offset>(begin: _getBeginOffset(direction), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      );

  static Offset _getBeginOffset(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.up: return const Offset(0, 1);
      case AxisDirection.down: return const Offset(0, -1);
      case AxisDirection.left: return const Offset(1, 0);
      case AxisDirection.right: return const Offset(-1, 0);
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 600;
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DelayedAnimation(
                  delayMs: 300,
                  child: Text(
                    'MORUBA',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 48 : 58,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The Ancient Board Game',
                  style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.white.withOpacity(0.9), fontStyle: FontStyle.italic),
                ),
                SizedBox(height: isSmallScreen ? 30 : 60),
                DelayedAnimation(
                  delayMs: 600,
                  child: AnimatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/mode'),
                    child: Container(
                      width: isSmallScreen ? 180 : 200,
                      height: isSmallScreen ? 50 : 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.amber.shade400]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.amber.shade800.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: Text('PLAY', style: TextStyle(fontSize: isSmallScreen ? 20 : 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),
                DelayedAnimation(
                  delayMs: 900,
                  child: AnimatedButton(
                    // EDITED HERE: Changed from pushNamed to direct MaterialPageRoute
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HowToPlayScreen()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 15 : 20, vertical: isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text('HOW TO PLAY', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DelayedAnimation extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const DelayedAnimation({super.key, required this.child, required this.delayMs});

  @override
  State<DelayedAnimation> createState() => _DelayedAnimationState();
}

class _DelayedAnimationState extends State<DelayedAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _animation.value)),
          child: Opacity(opacity: _animation.value.clamp(0.0, 1.0), child: child),
        );
      },
      child: widget.child, 
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const AnimatedButton({super.key, required this.child, required this.onPressed});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.95, upperBound: 1.0);
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
      appBar: AppBar(title: const Text('Select Mode'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.purple.shade700])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedButton(
                onPressed: () => Navigator.pushNamed(context, '/offline'),
                child: _MenuCard('OFFLINE', Colors.amber),
              ),
              const SizedBox(height: 40),
              AnimatedButton(
                onPressed: () => Navigator.pushNamed(context, '/online'),
                child: _MenuCard('ONLINE', Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _MenuCard(String title, MaterialColor color) {
  return Container(
    width: 250,
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.shade600, color.shade400]),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [BoxShadow(color: color.shade800.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))],
    ),
    child: Center(
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
    ),
  );
}

class OfflineModeScreen extends ConsumerWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int currentSize = ref.watch(boardSizeProvider);
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 500; 

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Mode'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.blue.shade800])),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isSmall ? 60 : 0),
                
                Text("PITS PER ROW", style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                SizedBox(height: isSmall ? 8 : 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [12, 18, 24, 32].map((boardSize) {
                    bool isSelected = currentSize == boardSize;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () => ref.read(boardSizeProvider.notifier).state = boardSize,
                        child: Container(
                          width: isSmall ? 40 : 45, 
                          height: isSmall ? 40 : 45,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.amberAccent : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                          ),
                          child: Center(
                            child: Text('$boardSize', style: TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.black87 : Colors.white)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: isSmall ? 25 : 50),
                
                AnimatedButton(
                  onPressed: () => _showMatchSetupDialog(context, ref, currentSize, true),
                  child: _SubMenuCard('SINGLE PLAYER', Icons.person, isSmall),
                ),
                SizedBox(height: isSmall ? 15 : 30),
                
                AnimatedButton(
                  onPressed: () => _showMatchSetupDialog(context, ref, currentSize, false),
                  child: _SubMenuCard('TWO PLAYERS', Icons.people, isSmall),
                ),
                SizedBox(height: isSmall ? 20 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMatchSetupDialog(BuildContext context, WidgetRef ref, int boardSize, bool isSinglePlayer) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 500;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        AIDifficulty selectedDiff = AIDifficulty.expert;
        FirstPlayerChoice startingChoice = FirstPlayerChoice.player1;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (builderContext, setState) {
                return Container(
                  width: 480,
                  constraints: BoxConstraints(maxHeight: size.height * 0.95),
                  padding: EdgeInsets.all(isSmall ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.purple.shade900]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24, width: 2)
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('MATCH SETUP', style: TextStyle(color: Colors.white, fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: isSmall ? 16 : 24),
                        
                        if (isSinglePlayer) ...[
                          Text('SELECT DIFFICULTY', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                            children: AIDifficulty.values.map((level) => InkWell(
                              onTap: () => setState(() => selectedDiff = level),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedDiff == level ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selectedDiff == level ? Colors.amber : Colors.white30, width: selectedDiff == level ? 2 : 1)
                                ),
                                child: Center(child: Text(level.name.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold))),
                              ),
                            )).toList(),
                          ),
                          SizedBox(height: isSmall ? 16 : 24),
                        ],

                        Text('WHO PLAYS FIRST?', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                          children: FirstPlayerChoice.values.map((choice) {
                            String label = choice == FirstPlayerChoice.player1 ? 'PLAYER 1' : 
                                           choice == FirstPlayerChoice.player2 ? (isSinglePlayer ? 'COMPUTER' : 'PLAYER 2') : 'RANDOM';
                            return InkWell(
                              onTap: () => setState(() => startingChoice = choice),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 120,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: startingChoice == choice ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: startingChoice == choice ? Colors.greenAccent : Colors.white30, width: startingChoice == choice ? 2 : 1)
                                ),
                                child: Center(child: Text(label, style: TextStyle(color: Colors.white, fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold))),
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: isSmall ? 20 : 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('CANCEL', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 14 : 16)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade600,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                              ),
                              onPressed: () {
                                Player startPlayer = startingChoice == FirstPlayerChoice.player1 ? Player.player1 :
                                                     startingChoice == FirstPlayerChoice.player2 ? Player.player2 :
                                                     (math.Random().nextBool() ? Player.player1 : Player.player2);
                                                     
                                ref.read(gameModeProvider.notifier).state = isSinglePlayer ? GameMode.singlePlayer : GameMode.twoPlayer;
                                ref.read(gameProvider.notifier).setGameMode(isSinglePlayer);
                                ref.read(gameProvider.notifier).resetGame(
                                  newSize: boardSize, 
                                  difficulty: selectedDiff,
                                  startingPlayer: startPlayer,
                                );
                                Navigator.pop(dialogContext);
                                Navigator.pushNamed(context, '/game');
                              },
                              child: Text('START GAME', style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold)),
                            )
                          ]
                        )
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
        );
      }
    );
  }
}

Widget _SubMenuCard(String title, IconData icon, bool isSmall) {
  return Container(
    width: 280,
    padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: isSmall ? 22 : 26, color: Colors.white),
        const SizedBox(width: 15),
        Text(title, style: TextStyle(fontSize: isSmall ? 16 : 20, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    ),
  );
}

class OnlineModeScreen extends ConsumerWidget {
  const OnlineModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSmall = MediaQuery.of(context).size.height < 500;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Online Mode'), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.purple.shade800])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedButton(onPressed: () {}, child: _SubMenuCard('PLAY WITH FRIEND', Icons.group, isSmall)),
              const SizedBox(height: 40),
              AnimatedButton(onPressed: () {}, child: _SubMenuCard('RANDOM MATCH', Icons.shuffle, isSmall)),
            ],
          ),
        ),
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
  final VoidCallback onModeChange;

  const _GameOverPanel({
    super.key,
    required this.winner, required this.player1Score, required this.player2Score, 
    required this.isSinglePlayer, required this.onRestart, required this.onModeChange,
  });

  @override
  State<_GameOverPanel> createState() => _GameOverPanelState();
}

class _GameOverPanelState extends State<_GameOverPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 500; 

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            width: math.min(size.width * 0.8, 480.0),
            constraints: BoxConstraints(maxHeight: size.height * 0.92),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 28, vertical: isSmall ? 12 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.blue.shade900.withOpacity(0.95), Colors.purple.shade900.withOpacity(0.95)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 25, spreadRadius: 5, offset: const Offset(0, 10))],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 8 : 12),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(Icons.emoji_events_rounded, size: isSmall ? 36 : 48, color: Colors.amberAccent),
                  ),
                  SizedBox(height: isSmall ? 8 : 16),
                  Text(
                    widget.winner.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isSmall ? 24 : 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5, shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))]),
                  ),
                  SizedBox(height: isSmall ? 12 : 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreBox('PLAYER 1', widget.player1Score, Colors.amber, isSmall),
                      Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 16)),
                      _buildScoreBox(widget.isSinglePlayer ? 'COMPUTER' : 'PLAYER 2', widget.player2Score, Colors.blueAccent, isSmall),
                    ],
                  ),
                  SizedBox(height: isSmall ? 16 : 24),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedButton(
                          onPressed: widget.onRestart,
                          child: Container(
                            height: isSmall ? 44 : 50,
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.amber.shade400]), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.replay_rounded, color: Colors.white, size: isSmall ? 20 : 24),
                                const SizedBox(width: 6),
                                Text('PLAY AGAIN', style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedButton(
                          onPressed: widget.onModeChange,
                          child: Container(
                            height: isSmall ? 44 : 50,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white30, width: 1.5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.grid_view_rounded, color: Colors.white, size: isSmall ? 20 : 24),
                                const SizedBox(width: 6),
                                Text('MODES', style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 4 : 8),
                  TextButton.icon(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    icon: const Icon(Icons.home_rounded, color: Colors.white70, size: 16),
                    label: const Text('Return to Main Menu', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBox(String label, int score, Color themeColor, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: isSmall ? 8 : 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: themeColor.withOpacity(0.3), width: 1)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: themeColor, fontSize: isSmall ? 10 : 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text('$score', style: TextStyle(fontSize: isSmall ? 20 : 24, fontWeight: FontWeight.w900, color: Colors.white)),
          Text('stones', style: TextStyle(color: Colors.white38, fontSize: isSmall ? 10 : 11)),
        ],
      ),
    );
  }
}

class _PauseMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onModeChange;
  final VoidCallback onHome;

  const _PauseMenu({super.key, required this.onResume, required this.onRestart, required this.onModeChange, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.purple.shade900]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 2)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('PAUSED', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 30),
              _buildBtn('RESUME', Icons.play_arrow, Colors.green.shade500, onResume),
              const SizedBox(height: 12),
              _buildBtn('RESTART MATCH', Icons.refresh, Colors.amber.shade600, onRestart),
              const SizedBox(height: 12),
              _buildBtn('CHANGE MODES', Icons.grid_view, Colors.blue.shade500, onModeChange),
              const SizedBox(height: 12),
              _buildBtn('MAIN MENU', Icons.home, Colors.red.shade500, onHome),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String title, IconData icon, Color theme, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.withOpacity(0.8), width: 1.5)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  final Player player;
  final bool isActive;
  final int score;
  final bool isAI;
  final String labelSuffix; 

  const _PlayerInfo({
    super.key,
    required this.player, 
    required this.isActive, 
    required this.score, 
    this.isAI = false, 
    this.labelSuffix = "", 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
            ? (player == Player.player1 ? [Colors.amber.withOpacity(0.4), Colors.transparent] : [Colors.transparent, Colors.blue.withOpacity(0.4)])
            : [Colors.transparent, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: player == Player.player1 ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${isAI ? "COMPUTER" : "PLAYER"}$labelSuffix - $score stones',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          if (isActive) const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10), 
            child: Text("(YOUR TURN)", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}

class _BoardLayout extends ConsumerStatefulWidget {
  final GameState boardState;

  const _BoardLayout({super.key, required this.boardState});

  @override
  ConsumerState<_BoardLayout> createState() => _BoardLayoutState();
}

class _BoardLayoutState extends ConsumerState<_BoardLayout> {
  late MorubaBoardGame game;

  @override
  void initState() {
    super.initState();
    game = MorubaBoardGame(
      state: widget.boardState,
      onPitTapped: (index) {
        final state = ref.read(gameProvider);
        final notifier = ref.read(gameProvider.notifier);
        
        if (state.isSinglePlayer && state.currentPlayer == Player.player2) return;
        if (state.movingStones.isNotEmpty || state.isPaused) return;

        if (state.canCapture) {
          notifier.bankStones(index);
        } else {
          notifier.makeMove(index);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant _BoardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    game.state = widget.boardState;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: GameWidget(
        game: game,
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.amber),
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

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (state.winner != null) {
          notifier.resetGame();
          Navigator.pushNamedAndRemoveUntil(context, '/mode', (route) => route.isFirst);
        } else {
          notifier.togglePause();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand, 
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
            LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final playerInfoHeight = math.min(availableHeight * 0.08, 36.0);
                final boardHeight = availableHeight - 2 * playerInfoHeight;

                return Column(
                  children: [
                    SizedBox(
                      height: playerInfoHeight,
                      child: gameMode == GameMode.singlePlayer
                          ? _PlayerInfo(player: Player.player2, isActive: state.currentPlayer == Player.player2, score: state.board.getBank(Player.player2).stones, isAI: true, labelSuffix: " (${state.aiDifficulty.name.toUpperCase()})")
                          : _PlayerInfo(player: Player.player2, isActive: state.currentPlayer == Player.player2, score: state.board.getBank(Player.player2).stones),
                    ),
                    SizedBox(
                      height: boardHeight,
                      child: _BoardLayout(key: ValueKey(state.matchId), boardState: state),
                    ),
                    SizedBox(
                      height: playerInfoHeight,
                      child: _PlayerInfo(player: Player.player1, isActive: state.currentPlayer == Player.player1, score: state.board.getBank(Player.player1).stones),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 45,
              left: 10,
              child: AnimatedButton(
                onPressed: () => notifier.togglePause(),
                child: const Icon(Icons.pause, color: Colors.white, size: 28, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
              ),
            ),
            if (state.canCapture || state.canBank)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      state.currentPlayer == Player.player1
                          ? (state.canCapture ? 'Capture available! Tap opponent pits' : 'Bank stones: Tap an opponent pit')
                          : 'Computer is making a move...', 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            if (state.winner != null)
              Container(
                color: Colors.black.withOpacity(0.85),
                child: _GameOverPanel(
                  winner: state.winner == Player.player1 ? "Player 1 Wins!" : "Computer Wins!",
                  player1Score: state.board.getBank(Player.player1).stones,
                  player2Score: state.board.getBank(Player.player2).stones,
                  isSinglePlayer: gameMode == GameMode.singlePlayer,
                  onRestart: notifier.resetGame,
                  onModeChange: () {
                    notifier.resetGame();
                    Navigator.pushNamedAndRemoveUntil(context, '/mode', (route) => route.isFirst);
                  },
                ),
              ),
            if (state.isPaused && state.winner == null)
              _PauseMenu(
                onResume: () => notifier.togglePause(),
                onRestart: () {
                  notifier.resetGame();
                },
                onModeChange: () {
                  notifier.resetGame();
                  Navigator.pushNamedAndRemoveUntil(context, '/mode', (route) => route.isFirst);
                },
                onHome: () {
                  notifier.resetGame();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
          ],
        ),
      ),
    );
  }
}