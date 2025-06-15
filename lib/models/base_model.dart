// BaseModel defines the contract for all models.
// Each model must implement:
// - String get id;
// - Map<String, dynamic> toJson();
// - A static or factory fromJson(Map<String, dynamic>) method.
abstract class BaseModel {
  String get id;
  Map<String, dynamic> toJson();
}

// FirestoreModel removed as it is not needed.
