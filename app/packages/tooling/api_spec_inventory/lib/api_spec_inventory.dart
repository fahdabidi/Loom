class ApiSpecInventoryItem {
  const ApiSpecInventoryItem({
    required this.componentId,
    required this.contractName,
    required this.phase,
    required this.status,
  });

  final String componentId;
  final String contractName;
  final String phase;
  final String status;
}

class ApiSpecInventorySchema {
  static const int schemaVersion = 1;
  static const List<String> allowedStatuses = [
    'planned',
    'draft',
    'implemented',
    'validated',
  ];

  const ApiSpecInventorySchema._();
}
