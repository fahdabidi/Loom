import 'package:loom_permission_parity_gate/loom_permission_parity_gate.dart';
import 'package:test/test.dart';

void main() {
  group('buildLiveRoleGrantsSql', () {
    test('joins app_role and role_permission on BOTH app_id and role_id', () {
      final sql = buildLiveRoleGrantsSql('loom_communities');
      expect(
        sql,
        contains('on rp.app_id = r.app_id and rp.role_id = r.role_id'),
        reason:
            'a join on role_id alone attributes another app\'s same-named '
            'role grants to this app',
      );
    });

    test('scopes the read to the given app id', () {
      final sql = buildLiveRoleGrantsSql('ai_controller');
      expect(sql, contains("where r.app_id = 'ai_controller'"));
    });

    test('a different app id changes the filter, not just the label', () {
      final loom = buildLiveRoleGrantsSql('loom_communities');
      final other = buildLiveRoleGrantsSql('ai_controller');
      expect(loom, isNot(equals(other)));
      expect(loom, contains("r.app_id = 'loom_communities'"));
      expect(other, contains("r.app_id = 'ai_controller'"));
    });

    test('rejects an app id containing a quote', () {
      expect(
        () => buildLiveRoleGrantsSql("loom'; drop table app_role; --"),
        throwsArgumentError,
      );
    });

    test('rejects an app id containing a space', () {
      expect(() => buildLiveRoleGrantsSql('loom communities'), throwsArgumentError);
    });

    test('rejects an empty app id', () {
      expect(() => buildLiveRoleGrantsSql(''), throwsArgumentError);
    });

    test('accepts the documented default app id', () {
      expect(
        () => buildLiveRoleGrantsSql('loom_communities'),
        returnsNormally,
      );
    });
  });

  group('LiveRoleGrantsReader.appId', () {
    test('defaults to loom_communities', () {
      const reader = LiveRoleGrantsReader();
      expect(reader.appId, 'loom_communities');
    });

    test('can be overridden to another app', () {
      const reader = LiveRoleGrantsReader(appId: 'ai_controller');
      expect(reader.appId, 'ai_controller');
    });
  });
}
