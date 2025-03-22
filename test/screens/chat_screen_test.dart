import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safechat/models/user_model.dart';
import 'package:safechat/screens/chat_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fake_async/fake_async.dart';

// Generate mock classes
@GenerateMocks([AudioPlayer])
import 'chat_screen_test.mocks.dart';

void main() {
  late MockAudioPlayer mockAudioPlayer;
  late UserModel userModel;

  setUp(() {
    mockAudioPlayer = MockAudioPlayer();
    userModel = UserModel();
    userModel.login('TestUser');

    // Stub audio player methods
    when(mockAudioPlayer.play(any, volume: anyNamed('volume')))
        .thenAnswer((_) async => null);
    when(mockAudioPlayer.play(any)).thenAnswer((_) async => null);
    when(mockAudioPlayer.stop()).thenAnswer((_) async => null);
    when(mockAudioPlayer.release()).thenAnswer((_) async => null);
  });

  Future<void> pumpChatScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: userModel,
          child: ChatScreen(
            audioPlayer: mockAudioPlayer,
            enableAnimations: false,
            enableDecayTimer: false,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ChatScreen Widget Tests', () {
    testWidgets('should display empty state message when no messages',
        (WidgetTester tester) async {
      await pumpChatScreen(tester);
      expect(find.text('No messages yet...'), findsOneWidget);
    });

    testWidgets('should display message input field and send button',
        (WidgetTester tester) async {
      await pumpChatScreen(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should add message when send button is pressed',
        (WidgetTester tester) async {
      await pumpChatScreen(tester);

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithText(ListTile, 'Test message'), findsOneWidget);
      expect(find.textContaining('TestUser'), findsOneWidget);
    });

    testWidgets('should show app bar with correct title',
        (WidgetTester tester) async {
      await pumpChatScreen(tester);
      expect(find.text('SafeChat: Wasteland v1.0.0'), findsOneWidget);
    });

    testWidgets('should show debug button and logout button in app bar',
        (WidgetTester tester) async {
      await pumpChatScreen(tester);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('should add debug message when debug button is pressed',
        (WidgetTester tester) async {
      await pumpChatScreen(tester);

      await tester.tap(find.byIcon(Icons.bug_report));
      await tester.pump();

      expect(find.text('Debug message from the wasteland!'), findsOneWidget);
      expect(find.textContaining('WastelandBot'), findsOneWidget);
    });

    testWidgets('should show message decay time', (WidgetTester tester) async {
      await pumpChatScreen(tester);

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Decays in'), findsOneWidget);
    });

    testWidgets('should navigate back on logout', (WidgetTester tester) async {
      bool didPop = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: userModel,
            child: ChatScreen(
              audioPlayer: mockAudioPlayer,
              enableAnimations: false,
              enableDecayTimer: false,
            ),
          ),
          navigatorObservers: [
            MockNavigatorObserver(onPop: () => didPop = true),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      expect(didPop, isTrue);
    });
  });
}

class MockNavigatorObserver extends NavigatorObserver {
  final Function onPop;

  MockNavigatorObserver({required this.onPop});

  @override
  void didPop(Route route, Route? previousRoute) {
    onPop();
  }
}
