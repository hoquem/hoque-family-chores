// --- Shared Enums (used across multiple domains) ---

/// Authentication status used across the app
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  unknown,
  authenticating,
  error,
}

/// UI/Provider state enums used across multiple providers
enum AvailableTasksState { loading, loaded, error, claiming }