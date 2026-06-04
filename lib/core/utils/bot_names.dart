import 'dart:math';

class BotNames {
  BotNames._();

  static const List<String> _names = [
    'Arjun Nair',
    'Meera Pillai',
    'Vishnu Menon',
    'Anjali Krishnan',
    'Aditya Varma',
    'Devika Suresh',
    'Rahul Mohan',
    'Lakshmi Raj',
    'Sreekanth Pillai',
    'Nithya Chandran',
    'Arun Kumar',
    'Priya Nambiar',
    'Jithin Thomas',
    'Sneha Gopalakrishnan',
    'Abhijith Menon',
    'Kavya Sunil',
    'Midhun Rajan',
    'Reshma Vijayan',
    'Unnikrishnan Nair',
    'Athira Prasad',
    'Sanjay Madhavan',
    'Gopika Ramesh',
    'Akash Babu',
    'Swathi Murali',
    'Nikhil Sreenivas',
  ];
  static String randomName([Random? random]) {
    final rng = random ?? Random();
    return _names[rng.nextInt(_names.length)];
  }

  static String generateBotUid([Random? random]) {
    final rng = random ?? Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final suffix = List.generate(
      12,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    return 'bot_$suffix';
  }

  static bool isBotUid(String uid) => uid.startsWith('bot_');
}
