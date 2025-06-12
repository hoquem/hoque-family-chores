import 'package:hoque_family_chores/scripts/initialize_firestore.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

void main() async {
  try {
    logger.i("Starting Firestore initialization command...");
    final initializer = FirestoreInitializer();
    await initializer.initializeCollections();
    logger.i("Firestore initialization command completed successfully.");
  } catch (e, s) {
    logger.e(
      "Error running Firestore initialization command: $e",
      error: e,
      stackTrace: s,
    );
    rethrow;
  }
}
