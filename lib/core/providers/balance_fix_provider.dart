import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the number of account balances auto-fixed on startup.
/// NavigationShell listens to this and shows a notification when > 0.
final balanceFixCountProvider = StateProvider<int>((ref) => 0);
