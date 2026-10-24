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
