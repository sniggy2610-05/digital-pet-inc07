import 'package:flutter/material.dart';
import 'pet_model.dart';

Color moodColor(Mood m) => switch (m) {
  Mood.happy => Colors.green,
  Mood.neutral => Colors.yellow,
  Mood.unhappy => Colors.red,
};

double moodScale(Mood m) => switch (m) {
  Mood.happy => 1.06,
  Mood.neutral => 1.0,
  Mood.unhappy => 0.94,
};

IconData moodIcon(Mood m) => switch (m) {
  Mood.happy => Icons.sentiment_very_satisfied,
  Mood.neutral => Icons.sentiment_neutral,
  Mood.unhappy => Icons.sentiment_very_dissatisfied,
};

/// Tinted pet + bounce + action reaction emoji.
class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.mood,
    required this.bounce,
    required this.reaction,
    required this.reduceMotion,
  });

  final Mood mood;
  final bool bounce;
  final String? reaction;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final fast = reduceMotion ? Duration.zero : const Duration(milliseconds: 180);
    final slow = reduceMotion ? Duration.zero : const Duration(milliseconds: 400);
    final scale = moodScale(mood) * (bounce && !reduceMotion ? 1.12 : 1.0);

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: AnimatedSlide(
            offset: reaction == null || reduceMotion
                ? Offset.zero
                : const Offset(0, -0.3),
            duration: slow,
            child: AnimatedOpacity(
              opacity: reaction == null ? 0 : 1,
              duration: slow,
              child: Text(reaction ?? '', style: const TextStyle(fontSize: 28)),
            ),
          ),
        ),
        AnimatedScale(
          scale: scale,
          duration: fast,
          curve: Curves.easeOutBack,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(moodColor(mood), BlendMode.modulate),
            child: Image.asset(
              'assets/pet.png',
              width: 160,
              height: 160,
              semanticLabel: 'Your pet',
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.pets, size: 140, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Speech bubble that cross-fades when the (derived) message changes.
class PetSpeech extends StatelessWidget {
  const PetSpeech({super.key, required this.message, required this.reduceMotion});
  final String message;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        child: Text(
          message,
          key: ValueKey(message),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// Meter that glides to its value; number is always shown too.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.label,
    required this.value,
    required this.reduceMotion,
  });

  final String label;
  final int value;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value out of 100',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label)),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value / 100),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text('$value', textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}