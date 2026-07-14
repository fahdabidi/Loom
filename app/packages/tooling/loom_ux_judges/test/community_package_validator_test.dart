import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:test/test.dart';

Map<String, dynamic> package({Map<String, dynamic>? experience}) => {
  'schemaVersion': 1,
  'experience': experience ?? {
    'experienceSchemaVersion': 2, 'workflowGrammarVersion': 1,
    'workflowDefinitions': {'thing': definition()}, 'workflowInstances': [instance()],
  },
};
Map<String, dynamic> definition({Map<String, dynamic>? schema, Map<String, dynamic>? transition}) => {
  'initialState': 'open', 'states': {'open': {'label': 'Open'}, 'done': {'label': 'Done', 'isTerminal': true}},
  'transitions': [transition ?? {'id': 'finish', 'label': 'Finish', 'from': ['open'], 'to': 'done'}], 'instanceDataSchema': schema ?? {},
};
Map<String, dynamic> instance({String id = 'one', String type = 'thing', String state = 'open', Map<String, dynamic> data = const {}}) => {'instanceId': id, 'workflowType': type, 'currentState': state, 'instanceData': data};
List<String> types(Map<String, dynamic> value) => CommunityPackageValidator().validate(value).findings.map((f) => f.type).toList();

void main() {
  group('CommunityPackageValidator', () {
    test('valid v2 package passes', () => expect(CommunityPackageValidator().validate(package()).passed, isTrue));
    test('validates version stamps and v1 short circuit', () {
      expect(types({'experience': {}}), contains('missing_schema_version'));
      expect(types(package(experience: {'experienceSchemaVersion': 99})), contains('unsupported_schema_version'));
      final legacy = CommunityPackageValidator().validate(package(experience: {'experienceSchemaVersion': 1}));
      expect(legacy.warnings.map((f) => f.type), ['legacy_experience_schema']); expect(legacy.errors, isEmpty);
    });
    test('validates instance identity, type, state and data', () {
      final p = package(); final e = p['experience'] as Map<String, dynamic>;
      e['workflowInstances'] = [instance(type: 'nope'), instance(id: 'two', state: 'nope'), instance(id: 'two'), instance(id: 'three', data: {'nope': 1})];
      expect(types(p), containsAll(['unknown_instance_workflow_type', 'invalid_instance_state', 'duplicate_instance_id', 'unknown_instance_data_key']));
    });
    test('validates required and computed seeded fields', () {
      final p = package(); final e = p['experience'] as Map<String, dynamic>; e['workflowDefinitions'] = {'thing': definition(schema: {'name': {'type': 'string', 'required': true}, 'computed': {'type': 'number', 'formula': '1'}})}; e['workflowInstances'] = [instance(data: {'computed': 1})];
      expect(types(p), containsAll(['missing_required_field', 'computed_field_seeded']));
    });
    test('malformed definition is reported', () { final p = package(); (p['experience'] as Map)['workflowDefinitions'] = {'bad': {}}; expect(types(p), contains('invalid_workflow_definition')); });
    test('cross-instance references validate and recurse', () {
      final p = package(); final e = p['experience'] as Map<String, dynamic>;
      e['workflowDefinitions'] = {
        'event': definition(schema: {'going': {'type': 'list'}, 'selected': {'type': 'string'}}),
        'ballot': definition(schema: {'eventId': {'type': 'string'}}, transition: {'id': 'vote', 'label': 'Vote', 'from': ['open'], 'to': 'done', 'guard': {'relatedInstanceField': 'eventId', 'relatedListField': 'going'}, 'effects': [{'op': 'branch', 'if': 'true', 'then': [{'op': 'set', 'key': 'selected', 'relatedInstance': 'eventId'}]}]}),
      };
      e['workflowInstances'] = [instance(id: 'event', type: 'event'), instance(id: 'ballot', type: 'ballot', data: {'eventId': 'event'})];
      expect(CommunityPackageValidator().validate(p).findings.where((f) => f.type.startsWith('dangling_') || f.type == 'computed_field_written_by_effect'), isEmpty);
      ((e['workflowInstances'] as List)[1] as Map)['instanceData'] = {'eventId': 'missing'}; expect(types(p), contains('dangling_instance_reference'));
    });
    test('delegates workflow validator findings', () { final p = package(); (p['experience'] as Map)['workflowDefinitions'] = {'thing': {'initialState': 'open', 'states': <String, dynamic>{'open': <String, dynamic>{'label': 'Open'}}, 'transitions': <dynamic>[], 'instanceDataSchema': <String, dynamic>{}}}; expect(types(p), contains('stuck_state')); });
  });
}
