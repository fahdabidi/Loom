class Persona {
  const Persona({
    required this.id,
    required this.passportId,
    required this.label,
    required this.isActive,
  });

  final String id;
  final String passportId;
  final String label;
  final bool isActive;
}
