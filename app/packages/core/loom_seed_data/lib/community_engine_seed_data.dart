class CommunityEngineSeed {
  const CommunityEngineSeed({
    required this.extensionId,
    required this.extensionVersion,
    required this.schemaId,
    required this.workflowId,
    required this.ruleId,
    required this.functionId,
    required this.initializationPackageId,
  });

  final String extensionId;
  final String extensionVersion;
  final String schemaId;
  final String workflowId;
  final String ruleId;
  final String functionId;
  final String initializationPackageId;
}

const communityEngineSeed = CommunityEngineSeed(
  extensionId: 'ext_book_club',
  extensionVersion: '1.0.0',
  schemaId: 'book_nomination',
  workflowId: 'book_vote_workflow',
  ruleId: 'rule_on_vote_close',
  functionId: 'fn_format_digest',
  initializationPackageId: 'init_book_club_1',
);
