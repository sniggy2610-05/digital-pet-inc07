import 'dart:async';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_widgets.dart';

// For testing, temporarily shorten these, then RESTORE before release build.
const Duration kHungerInterval = Duration(seconds: 30);
const Duration kWinDuration = Duration(minutes: 3);

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final PetModel _pet = PetModel();
  final TextEditingController _nameController =
  TextEditingController(text: 'Pip');

  String _petName = 'Pip';
  String _feedback = 'Choose an action to care for your pet.';
  String? _reaction;
  bool _bounce = false;
  bool _paused = false;

  Timer? _hungerTimer;
  Timer? _winTimer;
  Timer? _bounceTimer;
  Timer? _reactionTimer;

  @override
  void initState() {
    super.initState();
    _startHungerTimer();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _winTimer?.cancel();
    _bounceTimer?.cancel();
    _reactionTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // ---------- timers ----------
  void _startHungerTimer() {
    _hungerTimer?.cancel(); // guarantees exactly one active timer
    _hungerTimer = Timer.periodic(kHungerInterval, (timer) {
      if (!mounted || _pet.isFinished || _paused) {
        timer.cancel();
        return;
      }
      setState(_pet.tickHunger);
      _updateOutcome();
    });
  }

  void _cancelGameTimers() {
    _hungerTimer?.cancel();
    _winTimer?.cancel();
    _winTimer = null;
  }

  void _updateOutcome() {
    if (_pet.isFinished) return;

    if (_pet.lost) {
      _cancelGameTimers();
      setState(() => _pet.gameOver = true);
      return;
    }

    if (!_pet.highMood) {
      _winTimer?.cancel();
      _winTimer = null;
      return;
    }

    _winTimer ??= Timer(kWinDuration, () {
      _winTimer = null;
      if (!mounted || _pet.isFinished || !_pet.highMood) return;
      _hungerTimer?.cancel();
      setState(() => _pet.hasWon = true);
    });
  }

  // ---------- actions ----------
  void _act(String Function() action, String emoji) {
    if (_pet.isFinished || _paused) return;

    setState(() {
      _feedback = action();
      _reaction = emoji;
      _bounce = true;
    });

    _bounceTimer?.cancel();
    _bounceTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _bounce = false);
    });

    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _reaction = null);
    });

    _updateOutcome();
  }

  void _togglePause() {
    if (_pet.isFinished) return;
    if (_paused) {
      setState(() => _paused = false);
      _startHungerTimer();
      _updateOutcome(); // win countdown restarts fresh after a pause
    } else {
      _hungerTimer?.cancel();
      _winTimer?.cancel();
      _winTimer = null;
      setState(() => _paused = true);
    }
  }

  void _reset() {
    _winTimer?.cancel();
    _winTimer = null;
    setState(() {
      _pet.reset();
      _paused = false;
      _reaction = null;
      _feedback = 'Fresh start!';
    });
    _startHungerTimer();
  }

  void _confirmName() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _petName = text);
  }

  // ---------- derived presentation ----------
  String get _petMessage {
    if (_pet.gameOver) return 'I need a rest.';
    if (_pet.hasWon) return 'Best day ever!';
    if (_paused) return 'Paused...';
    if (_pet.hunger > 80) return "I'm starving!";
    if (_pet.happiness <= 30) return 'Play with me?';
    if (_pet.energy < 20) return 'So sleepy...';
    return "Hi, I'm $_petName!";
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final canAct = !_pet.isFinished && !_paused;
    final mood = _pet.mood;

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Pet')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Pet name',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _confirmName(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _confirmName, child: const Text('Set')),
                ],
              ),
              const SizedBox(height: 16),
              PetSpeech(message: _petMessage, reduceMotion: reduceMotion),
              const SizedBox(height: 8),
              PetAvatar(
                mood: mood,
                bounce: _bounce,
                reaction: _reaction,
                reduceMotion: reduceMotion,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(moodIcon(mood)),
                  const SizedBox(width: 6),
                  Text(
                    '$_petName is ${_pet.moodLabel}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MeterBar(
                  label: 'Happiness',
                  value: _pet.happiness,
                  reduceMotion: reduceMotion),
              MeterBar(
                  label: 'Hunger',
                  value: _pet.hunger,
                  reduceMotion: reduceMotion),
              MeterBar(
                  label: 'Energy',
                  value: _pet.energy,
                  reduceMotion: reduceMotion),
              const SizedBox(height: 12),
              Text(_feedback, textAlign: TextAlign.center),
              if (_pet.hasWon || _pet.gameOver)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _pet.hasWon ? '🏆 You win!' : '💀 Game over',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: canAct ? () => _act(_pet.feed, '🍖') : null,
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Feed'),
                  ),
                  FilledButton.icon(
                    onPressed: canAct ? () => _act(_pet.play, '🎾') : null,
                    icon: const Icon(Icons.sports_tennis),
                    label: const Text('Play'),
                  ),
                  FilledButton.icon(
                    onPressed: canAct ? () => _act(_pet.rest, '💤') : null,
                    icon: const Icon(Icons.bedtime),
                    label: const Text('Rest'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pet.isFinished ? null : _togglePause,
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    label: Text(_paused ? 'Resume' : 'Pause'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}