# Lab 6: Real-Time Data Ticker with AsyncValue

**Course:** Mobile Development — Riverpod Module  
**Author:** Mukhammadali Khayotov  
**Student:** Laziz Khushmurodov  

---

## Part 2 Inline Questions

### 1. Why is the feed behind its own Provider instead of being constructed inside `tickerProvider`?
Placing `TickFeed` behind its own `Provider<TickFeed>` separates concerns and embraces dependency injection:
- **Testability:** In unit and widget tests, `tickFeedProvider` can be cleanly overridden with a mock, stub, or deterministic feed (such as `TickFeed(symbols: ['BTC'], failAfter: 1)`) via `ProviderScope(overrides: [...])` or `container.overrideWithValue(...)` without changing or hacking `tickerProvider`.
- **Reactivity & Configurability:** It allows the feed configuration (such as `failAfter` or symbol list) to reactively depend on other providers (e.g., a `StateProvider<int?>` for toggling failures dynamically in the UI).
- **Separation of Concerns:** The service lifecycle and configuration remain decoupled from the stream mapping logic.

### 2. What does `autoDispose` do when the user navigates away mid-stream?
When all listeners (e.g. `TickerPage` or other consuming widgets) unsubscribe or unmount because the user navigated away:
- Riverpod automatically cancels the active stream subscription.
- The `async*` generator function in `TickFeed.watch()` stops its execution loop, freeing up timers and memory.
- The provider's internal state is disposed. If the user navigates back to the page later, the provider re-executes cleanly from the initial state without leaking background streams.

### 3. What `AsyncValue` does `tickerProvider` hold during the 800 ms delay, and what is `hasValue` at that moment?
- During the initial 800 ms `Future.delayed` call before the first `yield`:
  - `tickerProvider` holds `AsyncLoading<List<Tick>>()`.
  - `hasValue` is `false` (and `value` is `null`), because no tick data has been emitted yet.

---

## Part 3 Exercises

### Exercise 3.3: Break the switch on purpose
When commenting out the `AsyncLoading()` arm from the switch expression:
- **Exact Analyzer Diagnostic:**
  ```text
  The type 'AsyncValue<List<Tick>>' is not exhaustively matched by the switch expression because it can be 'AsyncLoading<List<Tick>>'.
  Try adding a case for 'AsyncLoading<List<Tick>>', or add a default case. (non_exhaustive_switch_expression)
  ```
- **Significance:**
  `AsyncValue` is declared as a `sealed class` in Dart 3. The compiler enforces exhaustive pattern matching at compile time. If any subtype (`AsyncData`, `AsyncLoading`, or `AsyncError`) is not handled, compilation fails, preventing runtime unhandled state errors.

### Exercise 3.4: Pattern-match on content, not just state
Why must `AsyncData(value: [])` and `AsyncData(value: [final only])` come before the general `AsyncData(:final value)` arm?
- **Sequential Evaluation & Pattern Specificity:**
  In Dart 3 pattern matching, switch arms are evaluated from top to bottom. The first pattern that matches the incoming value executes.
- **Shadowing / Dead Code:**
  The pattern `AsyncData(:final value)` matches **any** instance of `AsyncData<List<Tick>>`, including empty lists and single-element lists. If placed above the more specific list patterns, it would always match first, shadowing the specific arms and making `AsyncData(value: [])` and `AsyncData(value: [final only])` unreachable dead code.

---

## Part 4 Exercises

### Exercise 4.3: Refresh vs Invalidate
- **Keeping previous rows visible during reload:**
  Both `ref.refresh(tickerProvider.future)` and `ref.invalidate(tickerProvider)` preserve the previous emission in `value` while transitioning the provider into an `isLoading` state. Because of our pattern `AsyncValue(:final value?, isLoading: true)`, both keep the previous rows visible on screen with a progress indicator rather than resetting to a blank full-screen spinner.
- **Why `refresh(...future)` returns something awaitable:**
  `ref.refresh(provider.future)` invalidates the provider and immediately returns the `Future` corresponding to the next value resolution. Flutter's `RefreshIndicator.onRefresh` requires a `Future<void>` to know when the pull-to-refresh animation should dismiss. `ref.invalidate(provider)`, on the other hand, returns `void` synchronously and does not provide an awaitable future for the completion of the refresh.

### Exercise 4.4: Distinguish a reconnect from a first load
- **Explanation:**
  `isRefreshing` is `true` specifically when an `AsyncValue` is in a loading state and already carries previously loaded data (`hasValue == true`), whereas `isReloading` is `true` when an `AsyncValue` is in a loading state and already carries either previous data or a previous error (`hasValue == true || hasError == true`).

---

## Checkpoint Questions

### 1. Which three subtypes make `AsyncValue` sealed, and what does the analyzer report when a switch expression misses one?
The three direct subtypes of `AsyncValue` are:
1. `AsyncData<T>`
2. `AsyncLoading<T>`
3. `AsyncError<T>`

When a switch expression misses one of these subtypes, the Dart analyzer reports a compile-time error:
```text
The type 'AsyncValue<T>' is not exhaustively matched by the switch expression because it can be '<MissingType><T>'. (non_exhaustive_switch_expression)
```
Because `AsyncValue` is sealed, the compiler guarantees that every possible subtype is accounted for without needing a fallback `default` arm.

### 2. When does `AsyncError.value` carry a non-null value, and when is it null?
- **Non-null (`hasValue == true`):** When the provider previously emitted valid data before the error occurred (e.g. during a live stream hiccup, network disconnection, or a subsequent failed refresh). Riverpod preserves the last known good data in `AsyncError.value` so that UI can continue displaying cached data with a notification banner.
- **Null (`hasValue == false`):** When the error occurs during the cold initial load before any data was ever emitted.

### 3. What is the difference between `ref.refresh(provider)`, `ref.refresh(provider.future)`, and `ref.invalidate(provider)`?
- `ref.invalidate(provider)`: Synchronously invalidates the provider's state, marking it dirty and scheduling re-evaluation. It returns `void`.
- `ref.refresh(provider)`: Equivalent to calling `ref.invalidate(provider)` followed by `ref.read(provider)`. It forces immediate recomputation and returns the newly produced state synchronously (usually `AsyncLoading`).
- `ref.refresh(provider.future)`: Invalidates the provider and returns a `Future` that resolves when the new value has finished loading. This is required for `RefreshIndicator.onRefresh` which needs to `await` completion.

### 4. Why does `AsyncValue(:final value?, isLoading: true)` need to sit above `AsyncData(:final value)`?
Pattern matching arms are evaluated top-to-bottom. When a provider with existing data is refreshing or reloading, its state has `hasValue == true` and `isLoading == true`. If `AsyncData(:final value)` were placed first, any `AsyncData` that is currently reloading would match the general data arm and ignore the loading state, preventing the UI from showing the progress bar or refresh indicator. Placing `AsyncValue(:final value?, isLoading: true)` above ensures that the active refresh state is prioritized and rendered.

### 5. Give one reason to prefer switch expressions over `.when(...)` for `AsyncValue`, and one situation where `.when` is still convenient.
- **Reason to prefer switch expressions:** Dart 3 pattern matching provides unmatched expressiveness. You can inspect internal properties (`:final value?`, `isLoading: true`), destructure nested collections (`AsyncData(value: [final only])`), and handle hybrid states (such as stale data under error: `AsyncError(:final error, :final value?)`) cleanly in a single flat structure.
- **Situation where `.when` is still convenient:** For simple, standard widgets with no nested pattern logic or stale-data handling, `.when(data: ..., loading: ..., error: ...)` is concise and provides built-in flags like `skipLoadingOnRefresh` and `skipLoadingOnReload`.

---

## Stretch Goals Implementation Notes

1. **Per-symbol providers:**
   Implemented `tickBySymbolProvider = StreamProvider.autoDispose.family<Tick, String>` in `ticker_providers.dart` using `ref.watch(tickerProvider.stream).expand((ticks) => ticks).where((tick) => tick.symbol == symbol)`.
2. **Flash on change:**
   Can be handled inside individual symbol rows by listening to tick price transitions via `ref.listen` in a `ConsumerWidget`.
3. **Backoff retry:**
   Configurable retry loop with incremental delays (1s, 2s, 4s) wrapped around the feed connection.
4. **`AsyncValue.guard`:**
   Demonstrated in `ticker_providers.dart` via `balanceProvider` wrapping simulated asynchronous calls with `AsyncValue.guard`, transforming try-catch blocks into structured `AsyncValue` outputs.
