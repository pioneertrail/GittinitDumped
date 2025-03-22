// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safechat/screens/chat_screen.dart';
import 'package:safechat/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => UserModel(),
          child: ChatScreen(
            audioPlayer: AudioPlayer(),
          ),
        ),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('No messages yet...'), findsOneWidget);
  });
}
