import 'package:flutter_test/flutter_test.dart';
import 'package:focus/providers/chat_provider.dart';

void main() {
  test('ChatState.copyWith can clear nullable error', () {
    final ChatState state = ChatState(error: 'Backend failed');

    final ChatState cleared = state.copyWith(error: null);

    expect(cleared.error, isNull);
  });
}
