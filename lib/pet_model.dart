enum Mood { happy, neutral, unhappy }

class PetModel {
  int happiness = 50;
  int hunger = 50;
  int energy = 70;
  bool gameOver = false;
  bool hasWon = false;

  static int clamp(int v) => v.clamp(0, 100).toInt();

  bool get isFinished => gameOver || hasWon;
  bool get highMood => happiness > 80; // strictly > 80
  bool get lost => hunger == 100 && happiness <= 10;

  Mood get mood => happiness > 70
      ? Mood.happy
      : happiness >= 30
      ? Mood.neutral
      : Mood.unhappy;

  String get moodLabel => switch (mood) {
    Mood.happy => 'Happy',
    Mood.neutral => 'Neutral',
    Mood.unhappy => 'Unhappy',
  };

  /// Each action returns a short feedback message for the UI.
  String feed() {
    if (isFinished) return '';
    final nextHunger = clamp(hunger - 10);
    final change = nextHunger < 30 ? -20 : 10; // overfeeding hurts mood
    hunger = nextHunger;
    happiness = clamp(happiness + change);
    return change < 0
        ? 'Too full! Happiness -20.'
        : 'Yum! Hunger -10, happiness +10.';
  }

  String play() {
    if (isFinished) return '';
    if (energy < 10) return 'Too tired to play. Let me rest!';
    happiness = clamp(happiness + 15);
    hunger = clamp(hunger + 10);
    energy = clamp(energy - 15);
    return 'Fun! Happiness +15, hunger +10, energy -15.';
  }

  String rest() {
    if (isFinished) return '';
    energy = clamp(energy + 30);
    hunger = clamp(hunger + 5);
    return 'Zzz... Energy +30, hunger +5.';
  }

  /// Hunger timer tick (every 30s).
  void tickHunger() {
    if (hunger + 5 > 100) {
      hunger = 100;
      happiness = clamp(happiness - 20);
    } else {
      hunger += 5;
    }
  }

  void reset() {
    happiness = 50;
    hunger = 50;
    energy = 70;
    gameOver = false;
    hasWon = false;
  }
}