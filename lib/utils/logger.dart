import 'package:logger/logger.dart';

/// A utility class for logging messages throughout the application.
///
/// This class provides a consistent way to log messages with different severity levels:
/// - [d] for debug messages
/// - [i] for info messages
/// - [w] for warning messages
/// - [e] for error messages
/// - [wtf] for critical errors
///
/// Each log message includes:
/// - Timestamp
/// - Log level
/// - Message
/// - Stack trace (for errors)
/// - Additional context (if provided)
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;

  /// Initialize the logger with custom settings.
  ///
  /// [methodCount] is the number of method calls to be displayed in the stack trace.
  /// [errorMethodCount] is the number of method calls to be displayed for errors.
  /// [lineLength] is the width of the log print.
  /// [colors] determines whether to use colors in the log output.
  /// [printEmojis] determines whether to print emojis for each log level.
  /// [printTime] determines whether to print the timestamp.
  void init({
    int methodCount = 2,
    int errorMethodCount = 8,
    int lineLength = 120,
    bool colors = true,
    bool printEmojis = true,
    bool printTime = true,
  }) {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: methodCount,
        errorMethodCount: errorMethodCount,
        lineLength: lineLength,
        colors: colors,
        printEmojis: printEmojis,
        printTime: printTime,
      ),
    );
  }

  /// Log a debug message.
  void d(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      Level.debug,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log an info message.
  void i(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      Level.info,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log a warning message.
  void w(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      Level.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log an error message.
  void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      Level.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Log a critical error message.
  void wtf(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      Level.wtf,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  void _log(
    Level level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (!_isInitialized) {
      _initializeDefault();
    }

    final contextStr = context != null ? ' Context: $context' : '';
    final errorStr = error != null ? ' Error: $error' : '';
    final stackStr = stackTrace != null ? '\n$stackTrace' : '';

    _logger.log(level, '$message$contextStr$errorStr$stackStr');
  }

  bool get _isInitialized => _logger != null;

  void _initializeDefault() {
    init(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    );
  }
}

/// A global instance of [AppLogger] that can be used throughout the application.
final logger = AppLogger();
