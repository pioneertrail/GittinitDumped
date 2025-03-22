import 'package:flutter_test/flutter_test.dart';
import 'package:safechat/models/message_model.dart';

void main() {
  group('Message Model Tests', () {
    test('should create a Message instance', () {
      final now = DateTime.now();
      final message = Message(
        text: 'Hello Wasteland',
        sender: 'TestUser',
        timestamp: now,
      );

      expect(message.text, equals('Hello Wasteland'));
      expect(message.sender, equals('TestUser'));
      expect(message.timestamp, equals(now));
    });

    test('should convert Message to Map', () {
      final now = DateTime.now();
      final message = Message(
        text: 'Hello Wasteland',
        sender: 'TestUser',
        timestamp: now,
      );

      final map = message.toMap();

      expect(map['text'], equals('Hello Wasteland'));
      expect(map['sender'], equals('TestUser'));
      expect(map['timestamp'], equals(now.millisecondsSinceEpoch));
    });

    test('should create Message from Map', () {
      final now = DateTime.now();
      final map = {
        'text': 'Hello Wasteland',
        'sender': 'TestUser',
        'timestamp': now.millisecondsSinceEpoch,
      };

      final message = Message.fromMap(map);

      expect(message.text, equals('Hello Wasteland'));
      expect(message.sender, equals('TestUser'));
      expect(message.timestamp.millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch));
    });

    test('should handle invalid Map', () {
      expect(
        () => Message.fromMap({
          'text': 42,
          'sender': 'TestUser',
          'timestamp': 'invalid',
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
