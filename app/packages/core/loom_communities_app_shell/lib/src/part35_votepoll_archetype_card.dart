part of '../loom_communities_app_shell.dart';

/// The real `votePoll` archetype: a JSON-declared ballot rendered through the
/// engine-native pipeline. Candidates come from the binding's repeater source,
/// the tally comes from the engine-computed `voteCounts` field, and every vote
/// is sent as the repeater-declared transition input.
///
/// Only a binding with a repeater is a ballot. The `tournament-event` summary
/// binding also uses the `votePoll` family, but has no repeater and therefore
/// remains on [GenericWorkflowInstanceCard] until its later attendance
/// milestone.
class VotePollArchetypeCard extends StatefulWidget {
  const VotePollArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.personaId,
    required this.onInstanceChanged,
    this.accent,
    this.modernTheme,
  });

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String personaId;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final Color? accent;
  final LoomCardTheme? modernTheme;

  @override
  State<VotePollArchetypeCard> createState() => _VotePollArchetypeCardState();
}

class _VotePollArchetypeCardState extends State<VotePollArchetypeCard> {
  List<LoomWorkflowTransition> _actions = const [];
  bool _loadingActions = true;
  bool _mutating = false;
  int _actionRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  @override
  void didUpdateWidget(covariant VotePollArchetypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldInstance = oldWidget.resolved.instance;
    final newInstance = widget.resolved.instance;
    if (oldInstance.instanceId != newInstance.instanceId ||
        oldInstance.currentState != newInstance.currentState ||
        oldWidget.personaId != widget.personaId ||
        oldWidget.engine != widget.engine) {
      _loadActions();
    }
  }

  @override
  void dispose() {
    _actionRequest++;
    super.dispose();
  }

  Future<void> _loadActions() async {
    final request = ++_actionRequest;
    if (mounted) setState(() => _loadingActions = true);
    try {
      final instance = widget.resolved.instance;
      final actions = await widget.engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        personaId: widget.personaId,
      );
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = actions;
        _loadingActions = false;
      });
    } catch (_) {
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = const [];
        _loadingActions = false;
      });
    }
  }

  RepeaterItemAction? get _voteItemAction {
    final repeater = widget.resolved.binding.repeater;
    if (repeater == null) return null;
    for (final itemAction in repeater.itemActions) {
      if (_actions.any((action) => action.id == itemAction.transitionId)) {
        return itemAction;
      }
    }
    return null;
  }

  bool get _canVote => _voteItemAction != null;

  bool get _canClose => _actions.any((action) => action.id == 'close-vote');

  dynamic _resolveItemInput(dynamic template, Map<String, dynamic> item) {
    if (template is! String) return template;
    final exact = RegExp(r'^\{item\.([^}]+)\}$').firstMatch(template);
    if (exact != null) return item[exact.group(1)];
    return template.replaceAllMapped(
      RegExp(r'\{item\.([^}]+)\}'),
      (match) => '${item[match.group(1)] ?? ''}',
    );
  }

  Map<String, dynamic>? _inputsForItem(Map<String, dynamic> item) {
    final declared = _voteItemAction?.inputs;
    if (declared == null) return null;
    return {
      for (final entry in declared.entries)
        entry.key: _resolveItemInput(entry.value, item),
    };
  }

  Future<void> _runMutation(Future<void> Function() mutate) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await mutate();
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
    if (!mounted) return;
    // The dispatcher's changed callback ignores its argument and re-queries
    // the engine. Passing the pre-mutation instance matches the established
    // event-rsvp archetype convention.
    widget.onInstanceChanged(widget.resolved.instance);
    await _loadActions();
  }

  Future<void> _vote(Map<String, dynamic> candidate) async {
    final itemAction = _voteItemAction;
    if (itemAction == null) return;
    final instance = widget.resolved.instance;
    await _runMutation(() async {
      await widget.engine.applyTransition(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        transitionId: itemAction.transitionId,
        personaId: widget.personaId,
        inputs: _inputsForItem(candidate),
      );
    });
  }

  Future<void> _closeVote() async {
    final instance = widget.resolved.instance;
    await _runMutation(() async {
      await widget.engine.applyTransition(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        transitionId: 'close-vote',
        personaId: widget.personaId,
      );
    });
  }

  void _showCandidateDetail(String instanceId, Map<String, dynamic> candidate) {
    final id = '${candidate['id']}';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: ValueKey('votepoll-detail-dialog-$instanceId-$id'),
        title: Text(
          '${candidate['name']}',
          key: ValueKey('votepoll-detail-name-$instanceId-$id'),
        ),
        content: Text(
          '${candidate['description'] ?? 'No description available.'}',
          key: ValueKey('votepoll-detail-description-$instanceId-$id'),
        ),
        actions: [
          TextButton(
            key: ValueKey('votepoll-detail-close-$instanceId-$id'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instance = widget.resolved.instance;
    final data = instance.instanceData;
    final foreground =
        widget.modernTheme?.resolvedHeading ??
        (widget.accent == null ? null : _foregroundFor(widget.accent!));
    final repeater = widget.resolved.binding.repeater;
    final candidateSource = repeater?.source ?? 'candidates';
    final candidates = <Map<String, dynamic>>[
      for (final entry in (data[candidateSource] as List? ?? const []))
        if (entry is Map) Map<String, dynamic>.from(entry),
    ];
    final rawVoteCounts = data['voteCounts'];
    final voteCounts = <String, int>{
      if (rawVoteCounts is Map)
        for (final entry in rawVoteCounts.entries)
          if (entry.value is num) '${entry.key}': (entry.value as num).toInt(),
    };
    final round = data['round']?.toString();
    final deadline = data['deadline']?.toString();
    final isExpiringSoon = data['isExpiringSoon'] == true;
    final outcome = data['outcome']?.toString();
    final winner = data['winner']?.toString();

    return Card(
      key: ValueKey('votepoll-card-${instance.instanceId}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (round != null && round.isNotEmpty)
              Text(
                'Round: $round',
                key: ValueKey('votepoll-round-${instance.instanceId}'),
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (deadline != null && deadline.isNotEmpty)
              Text(
                'Voting closes: $deadline',
                key: ValueKey('votepoll-deadline-${instance.instanceId}'),
                style: TextStyle(color: foreground),
              ),
            if (isExpiringSoon)
              Text(
                'Vote closing soon',
                key: ValueKey('votepoll-reminder-${instance.instanceId}'),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (outcome == 'decided' && winner != null && winner.isNotEmpty)
              Text(
                'Winner: $winner',
                key: ValueKey('votepoll-winner-${instance.instanceId}'),
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 8),
            for (final candidate in candidates)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  key: ValueKey(
                    'votepoll-candidate-${instance.instanceId}-${candidate['id']}',
                  ),
                  children: [
                    Expanded(
                      child: InkWell(
                        key: ValueKey(
                          'votepoll-candidate-name-${instance.instanceId}-${candidate['id']}',
                        ),
                        onTap: () => _showCandidateDetail(
                          instance.instanceId,
                          candidate,
                        ),
                        child: Text(
                          '${candidate['name']}: ${voteCounts['${candidate['id']}'] ?? 0} votes',
                          key: ValueKey(
                            'votepoll-candidate-count-${instance.instanceId}-${candidate['id']}',
                          ),
                          style: TextStyle(color: foreground),
                        ),
                      ),
                    ),
                    if (_canVote)
                      FilledButton(
                        key: ValueKey(
                          'votepoll-vote-${instance.instanceId}-${candidate['id']}',
                        ),
                        onPressed: _mutating
                            ? null
                            : () => unawaited(_vote(candidate)),
                        child: const Text('Vote'),
                      ),
                  ],
                ),
              ),
            if (_canClose) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                key: ValueKey('votepoll-close-vote-${instance.instanceId}'),
                onPressed: _mutating ? null : () => unawaited(_closeVote()),
                icon: const Icon(Icons.how_to_vote_outlined),
                label: const Text('Close vote'),
              ),
            ],
            if (_loadingActions || _mutating)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                  key: ValueKey('votepoll-progress-${instance.instanceId}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
