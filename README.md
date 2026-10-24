# Mobile Programming Lab 6: Real-Time Data Ticker with AsyncValue

This repository contains the complete implementation of Lab 6 (Riverpod AsyncValue module) according to the specifications in `Lab_6.pdf`.

## Project Structure

```
├── Lab_6.pdf                     # Lab assignment specification
├── NOTES.md                      # Lab notes, inline exercises & checkpoint answers
├── riverpod_ticker/              # Flutter project root
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   ├── NOTES.md
│   ├── lib/
│   │   ├── main.dart             # App entry point with ProviderScope
│   │   ├── ticker_page.dart      # Ticker UI with exhaustive pattern matching switch
│   │   ├── models/
│   │   │   └── tick.dart         # Immutable Tick data model
│   │   ├── providers/
│   │   │   └── ticker_providers.dart # Riverpod providers (stream, state, stretch family)
│   │   ├── services/
│   │   │   └── tick_feed.dart    # Simulated tick feed with on-demand failure
│   │   └── widgets/
│   │       └── tick_row.dart     # Individual tick row ListTile
│   └── test/
│       ├── ticker_providers_test.dart # Provider tests (loading, data, error with stale data)
│       └── ticker_page_test.dart      # Widget tests (loading, data, error, error-after-data)
```

## Running the Project

From the project directory:

```bash
cd riverpod_ticker
flutter pub get
flutter run
```

## Running the Tests

```bash
cd riverpod_ticker
flutter test
```

## Git Tags
- `p1-setup`: Part 1 Setup
- `p2-provider`: Part 2 Model and Stream Provider
- `p3-ui`: Part 3 Ticker UI with AsyncValue pattern matching
- `p4-resilience`: Part 4 Errors, retry, and preserving previous data
- `p5-tests`: Part 5 Provider & Widget Tests (6 tests)
