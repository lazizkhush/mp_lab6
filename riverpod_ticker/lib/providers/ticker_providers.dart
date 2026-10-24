import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tick.dart';
import '../services/tick_feed.dart';

final failAfterProvider = StateProvider<int?>((ref) => null);

/// Overridable in tests and in the error demo.
final tickFeedProvider = Provider<TickFeed>((ref) {
  return TickFeed(failAfter: ref.watch(failAfterProvider));
});

final tickerProvider = StreamProvider.autoDispose<List<Tick>>((ref) {
  return ref.watch(tickFeedProvider).watch();
});

/// Stretch Goal 1: Per-symbol family stream provider
final tickBySymbolProvider =
    StreamProvider.autoDispose.family<Tick, String>((ref, symbol) {
  return ref
      .watch(tickerProvider.stream)
      .expand((ticks) => ticks)
      .where((tick) => tick.symbol == symbol);
});

/// Stretch Goal 4: AsyncValue.guard balance provider
final balanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final result = await AsyncValue.guard(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 12450.75;
  });
  return result.requireValue;
});
