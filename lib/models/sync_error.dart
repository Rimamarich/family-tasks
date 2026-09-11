/// Représente une erreur de synchronisation ICS.
///
/// Une erreur est créée quand un événement du fichier ICS ne peut pas
/// être converti en tâche (membre inconnu, étoiles invalides, etc.).
class SyncError {
  const SyncError({
    this.id,
    required this.eventTitle,
    required this.errorMessage,
    required this.createdAt,
  });

  /// Identifiant en base (null avant insertion).
  final int? id;

  /// Titre de l'événement ICS qui a posé problème.
  final String eventTitle;

  /// Message d'erreur décrivant le problème.
  final String errorMessage;

  /// Date et heure auxquelles l'erreur a été détectée.
  final String createdAt;
}