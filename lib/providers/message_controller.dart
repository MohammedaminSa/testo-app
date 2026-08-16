import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single channel for transient messages (errors + confirmations) shown as
/// snackbars. Screens push a message here instead of owning their own
/// `ScaffoldMessenger` calls; the root [MessageHost] displays them.
class MessageController extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}

final messageControllerProvider =
    NotifierProvider<MessageController, String?>(MessageController.new);