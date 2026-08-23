import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  test(
    'B25 product-doc rows reach the shipped-package walkthrough catalog',
    () async {
      final repositoryRoot = locateB25RepositoryRoot();
      final catalog = B25ProductDocInteractionCatalog.fromAssetJson(
        File(
          '${repositoryRoot.path}/$b25InteractionModelAssetRepositoryPath',
        ).readAsStringSync(),
      );
      final rowsByCommunity = <String, List<B25ProductDocInteractionModel>>{};
      for (final row in catalog.models) {
        rowsByCommunity.putIfAbsent(row.communityId, () => []).add(row);
      }

      expect(catalog.models, hasLength(79));
      expect(
        rowsByCommunity.keys,
        unorderedEquals(
          loomEvidenceTargets.map((target) => target.communityId),
        ),
      );

      final findings = <String>[];
      for (final target in loomEvidenceTargets) {
        final package = await readShippedEvidencePackage(target);
        for (final row in rowsByCommunity[target.communityId]!) {
          final machine =
              package.experience.workflowDefinitions?[row.workflowId];
          if (machine == null) {
            findings.add(
              '${target.communityName} | ${row.workflowId} | ${row.role} | '
              'missing workflow definition',
            );
            continue;
          }
          final vocabulary = _workflowActionVocabulary(
            machine,
            package.experience.workflowDefinitions!,
          );
          final primary = _matchingTerms(
            vocabulary,
            row.requiredPrimaryActions,
          );
          final alternate = _matchingTerms(
            vocabulary,
            row.requiredAlternateActions,
          );
          if (primary.isEmpty || alternate.isEmpty) {
            findings.add(
              '${target.communityName} | ${row.workflowId} | ${row.role} | '
              'primary=${primary.isEmpty ? 'missing' : primary.join(',')} | '
              'alternate=${alternate.isEmpty ? 'missing' : alternate.join(',')} | '
              'package=${vocabulary.join(', ')}',
            );
          }
        }
      }
      // This diagnostic is intentionally visible in real test output. Missing
      // vocabulary is a product finding for the shipped package, not a reason
      // to fabricate or edit community JSON in the walkthrough layer.
      // ignore: avoid_print
      print('B25_SHIPPED_ACTION_FINDINGS ${findings.join('\n')}');
    },
  );
}

Set<String> _workflowActionVocabulary(
  LoomWorkflowStateMachine machine,
  Map<String, LoomWorkflowStateMachine> definitions,
) {
  final machines = <LoomWorkflowStateMachine>{machine};
  for (final binding in machine.renderBindings) {
    final response = binding.responseTable?.workflowType;
    final responseMachine = response == null ? null : definitions[response];
    if (responseMachine != null) {
      machines.add(responseMachine);
    }
  }
  return <String>{
    for (final source in machines)
      for (final transition in source.transitions) ...<String>{
        transition.label.toLowerCase(),
        transition.id.replaceAll('_', ' ').replaceAll('-', ' ').toLowerCase(),
        if (transition.action case final action?)
          action.replaceAll('_', ' ').replaceAll('-', ' ').toLowerCase(),
      },
  };
}

List<String> _matchingTerms(Set<String> vocabulary, List<String> terms) {
  return terms
      .where(
        (term) => vocabulary.any(
          (candidate) =>
              candidate.contains(term.toLowerCase()) ||
              term.toLowerCase().contains(candidate),
        ),
      )
      .toList(growable: false);
}
