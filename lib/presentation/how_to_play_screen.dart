import 'package:flutter/material.dart';
import 'dart:async';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: const Text('HOW TO PLAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: const [
          Text(
            '1. Basic Sowing',
            style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'When you select a pit, its stones are picked up and dropped one-by-one into the subsequent pits in a counter-clockwise direction.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 20),
          // Animation showing 4 stones being picked up and distributed
          AnimatedPitSequence(
            frames: [
              [4, 0, 0, 0, 0], // Start
              [0, 1, 0, 0, 0], // Drop 1
              [0, 1, 1, 0, 0], // Drop 2
              [0, 1, 1, 1, 0], // Drop 3
              [0, 1, 1, 1, 1], // Drop 4 (End)
            ],
          ),
          
          SizedBox(height: 40),
          
          Text(
            '2. Capturing (Jump Mechanics)',
            style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'If your last stone lands in an empty pit on your inner row, and the opponent has stones in the adjacent pits, those stones are captured.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 20),
          // Animation showing a final stone landing and capturing
          AnimatedPitSequence(
            frames: [
              [1, 0, 3, 3, 0], // Start (1 stone to move)
              [0, 1, 3, 3, 0], // Lands in empty pit
              [0, 1, 0, 0, 0], // Captures opponent's stones (represented by the 3s disappearing)
            ],
          ),

          SizedBox(height: 40),

          Text(
            '3. Single Stone Movement (Endgame)',
            style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'During the endgame, single stones can only be moved into empty adjacent pits.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 20),
          AnimatedPitSequence(
            frames: [
              [1, 0, 0, 0, 0], // Start
              [0, 1, 0, 0, 0], // Move 1 space
              [0, 0, 1, 0, 0], // Move 1 space
            ],
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// A reusable widget that loops through "frames" of stone counts to simulate movement.
class AnimatedPitSequence extends StatefulWidget {
  final List<List<int>> frames;
  final Duration frameDuration;

  const AnimatedPitSequence({
    super.key,
    required this.frames,
    this.frameDuration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedPitSequence> createState() => _AnimatedPitSequenceState();
}

class _AnimatedPitSequenceState extends State<AnimatedPitSequence> {
  int _currentFrame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(widget.frameDuration, (timer) {
      if (!mounted) return;
      setState(() {
        _currentFrame = (_currentFrame + 1) % widget.frames.length;
        
        // Add a slight pause at the end of the loop
        if (_currentFrame == 0) {
          _timer?.cancel();
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _startAnimation();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPits = widget.frames[_currentFrame];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: currentPits.map((stoneCount) {
          return _buildPit(stoneCount);
        }).toList(),
      ),
    );
  }

  Widget _buildPit(int stoneCount) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.brown.shade800,
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 5,
            offset: Offset(2, 2),
            // The inset property was removed from here to fix the build error
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            stoneCount > 0 ? '$stoneCount' : '',
            key: ValueKey<int>(stoneCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}