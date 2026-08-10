import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

WorkflowInstance _instance(String id, Map<String, dynamic> data) =>
    WorkflowInstance(
      instanceId: id,
      workflowType: 'tournament-event',
      currentState: 'open',
      instanceData: data,
      createdByPersonaId: 'tabletop-organizer',
    );

void main() {
  test('instance-scoped prefill resolves each host instance and its fields', () {
    final instanceA = _instance('tournament-summer', const {
      'title': 'Summer tournament',
      'location': 'Main hall',
    });
    final instanceB = _instance('tournament-autumn', const {
      'title': 'Autumn tournament',
      'location': 'Riverside hall',
    });
    const prefill = {
      'eventId': '{context.id}',
      'eventTitle': '{context.title}',
    };

    final resolvedA = resolveInstanceScopedPrefill(prefill, instanceA);
    final resolvedB = resolveInstanceScopedPrefill(prefill, instanceB);

    expect(resolvedA['eventId'], instanceA.instanceId);
    expect(resolvedB['eventId'], instanceB.instanceId);
    expect(resolvedA['eventId'], isNot(resolvedB['eventId']));
    expect(resolvedA['eventTitle'], instanceA.instanceData['title']);
    expect(resolvedB['eventTitle'], instanceB.instanceData['title']);
  });

  test(r'instance-scoped prefill resolves "$actor" and "$timestamp"', () {
    final instance = _instance('tournament-summer', const {
      'title': 'Summer tournament',
    });
    const prefill = {
      'ownerPersonaId': '\$actor',
      'createdAt': '\$timestamp',
    };

    final resolved = resolveInstanceScopedPrefill(
      prefill,
      instance,
      actorId: 'tabletop-organizer',
    );

    expect(resolved['ownerPersonaId'], 'tabletop-organizer');
    expect(
      DateTime.tryParse(resolved['createdAt'] as String),
      isNotNull,
    );
  });

  test(
    r'tab-scoped prefill resolves "$actor" and "$timestamp" without context tokens',
    () {
    const prefill = {
      'ownerPersonaId': '\$actor',
      'createdAt': '\$timestamp',
      'message': '\$actor is active at \$timestamp',
    };

    final resolved = resolveTabScopedPrefill(prefill, 'tabletop-member');

    expect(resolved['ownerPersonaId'], 'tabletop-member');
    expect(DateTime.tryParse(resolved['createdAt'] as String), isNotNull);
    expect(resolved['message'], contains('tabletop-member'));
  });
}
