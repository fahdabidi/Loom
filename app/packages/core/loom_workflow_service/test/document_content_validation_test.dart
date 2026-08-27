import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:test/test.dart';

/// Where a document library's content comes from, checked at install time.
///
/// Both rules exist because the answer was invisible. Five shipped document
/// libraries are lists of external links, which is exactly what their product
/// docs describe -- and nothing said so, so the platform's document storage
/// shipped with no package able to use it.
void main() {
  group('an upload that stores nothing', () {
    test('is an error when the location comes from member input', () {
      final findings = validateExecutableDefinitions({
        'soccer-waiver-document': _library(
          transitions: [
            {
              'id': 'prepare-new-version',
              'label': 'Publish new waiver version',
              'action': 'upload',
              'from': ['unread'],
              'to': null,
              'inputs': {
                'documentUrl': {'type': 'text', 'required': true},
              },
              'effects': [
                {'op': 'set', 'key': 'documentUrl', 'value': '{input.documentUrl}'},
              ],
            },
          ],
        ),
      });

      final finding = findings.singleWhere(
        (f) => f.code == 'document_upload_stores_no_content',
      );
      expect(finding.isError, isTrue);
      expect(finding.transitionId, 'prepare-new-version');
      // The message must say why it matters now, not just that it is odd.
      expect(finding.message, contains('grants permission'));
    });

    test('is accepted when the upload does not set the link field', () {
      final findings = validateExecutableDefinitions({
        'hoa-member-document': _library(
          transitions: [
            {
              'id': 'upload-document',
              'label': 'Upload',
              'action': 'upload',
              'from': ['unread'],
              'to': null,
              'effects': [
                {'op': 'set', 'key': 'uploadedAt', 'value': r'$timestamp'},
              ],
            },
          ],
        ),
      });

      expect(
        findings.where((f) => f.code == 'document_upload_stores_no_content'),
        isEmpty,
      );
    });
  });

  group('a library with no upload', () {
    test('warns without blocking the install', () {
      final findings = validateExecutableDefinitions({
        'chess-rules-documents': _library(
          transitions: [
            {
              'id': 'record-open',
              'label': 'Open',
              'action': 'open',
              'from': ['unread'],
              'to': null,
            },
          ],
        ),
      });

      final finding = findings.singleWhere(
        (f) => f.code == 'document_library_is_link_only',
      );
      // A link library is a legitimate product, so this must never reject one.
      expect(finding.isError, isFalse);
      expect(finding.message, contains('documentUrl'));

      // And nothing else in the definition may be treated as an error, or the
      // warning would block the install by proxy.
      expect(findings.where((f) => f.isError), isEmpty);
    });

    test('says nothing when the library declares no link field', () {
      final findings = validateExecutableDefinitions({
        'stored-only-library': _library(
          linkFieldType: 'text',
          transitions: [
            {
              'id': 'record-open',
              'label': 'Open',
              'action': 'open',
              'from': ['unread'],
              'to': null,
            },
          ],
        ),
      });

      expect(
        findings.where((f) => f.code == 'document_library_is_link_only'),
        isEmpty,
      );
    });
  });

  test('a non-document workflow is untouched by either rule', () {
    final findings = validateExecutableDefinitions({
      'some-form': {
        'initialState': 'draft',
        'states': {
          'draft': {'label': 'Draft'},
        },
        'renderBindings': [
          {
            'states': ['draft'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'formEntry',
            'bindingKind': 'primary',
            'actions': [
              {
                'kind': 'create',
                'label': 'Add',
                'scope': 'tab',
                'presentation': 'fab',
              },
            ],
          },
        ],
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'link': {'type': 'url', 'writableBy': 'formEntry'},
        },
      },
    });

    expect(
      findings.where(
        (f) =>
            f.code == 'document_library_is_link_only' ||
            f.code == 'document_upload_stores_no_content',
      ),
      isEmpty,
    );
  });
}

/// A documentLibrary workflow with one `url` content field.
Map<String, dynamic> _library({
  required List<Map<String, dynamic>> transitions,
  String linkFieldType = 'url',
}) => {
  'initialState': 'unread',
  'states': {
    'unread': {'label': 'Unread'},
  },
  'renderBindings': [
    {
      'states': ['unread'],
      'audience': 'any',
      'tabId': 'documents',
      'cardSurfaceFamily': 'documentLibrary',
      'bindingKind': 'primary',
      'actions': [
        {
          'kind': 'create',
          'label': 'Add document',
          'scope': 'tab',
          'presentation': 'fab',
        },
      ],
    },
  ],
  'transitions': transitions,
  'instanceDataSchema': {
    'documentUrl': {'type': linkFieldType, 'writableBy': 'formEntry'},
    'uploadedAt': {'type': 'date?', 'writableBy': 'effect'},
  },
};
