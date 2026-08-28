import 'dart:math';

class BotPlayerModel {
  final String name;
  final String avatar;

  BotPlayerModel({required this.name, required this.avatar});

  static final List<String> _botNames = [
    'سارا',
    'علی',
    'حسین',
    'رضا',
    'محمد',
    'مهدی',
    'لیلا',
    'ملینا',
  ];

  static List<BotPlayerModel> getRandomBots(int count) {
    final random = Random();
    final shuffled = List<String>.from(_botNames)..shuffle(random);
    return shuffled
        .take(count)
        .map((name) => BotPlayerModel(
              name: name,
              avatar: 'bot_avatar_${random.nextInt(5) + 1}',
            ))
        .toList();
  }
}
