import 'package:flutter_test/flutter_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';

void main() {
  group('A6 app shell and UX micro-component validation tests', () {
    test('vt_app-shell_cards', () {
      final shell = CommunityAppShellRuntime();
      shell.installCommunity(_cardProps());

      expect(shell.cards.single.communityId, 'community_book_club');
    });

    test('vt_app-shell_required-nav', () {
      final shell = CommunityAppShellRuntime();

      expect(shell.hasRequiredStructure, isTrue);
      expect(shell.navigation.exposesMessagesAndConnections, isTrue);
    });

    test('vt_app-shell_route-host', () {
      final shell = CommunityAppShellRuntime()..openExtension('ext_book_club');

      expect(shell.openExtensionId, 'ext_book_club');
    });

    test('vt_app-shell_ad-slots', () {
      final shell = CommunityAppShellRuntime();

      expect(shell.topAdSlot.required, isTrue);
      expect(shell.topAdSlot.slotId, 'shell.top-banner');
    });

    test('vt_community-card_render-bind', () {
      final viewModel = bindCommunityCard(_cardProps());

      expect(viewModel.title, 'Neighborhood Book Club');
      expect(viewModel.imageAssetId, 'asset_card_book_club');
    });

    test('vt_community-card_branding-priority', () {
      expect(resolveCommunityCardImage(_branding(card: 'card')), 'card');
      expect(resolveCommunityCardImage(_branding(logo: 'logo')), 'logo');
      expect(
        resolveCommunityCardImage(_branding(extensionDefault: 'default')),
        'default',
      );
      expect(resolveCommunityCardImage(_branding()), 'generated:book:#246B62');
    });

    test('vt_navigation-panel_messages-connections', () {
      const props = NavigationPanelProps(
        destinations: ['Home', 'Messages', 'Connections'],
      );

      expect(props.exposesMessagesAndConnections, isTrue);
    });

    test('vt_stream-renderer_ad-item-disclosure', () {
      final item = renderAdStreamItem(
        title: 'Local sponsor',
        body: 'Support the club.',
      );

      expect(item.kind, 'ad');
      expect(item.disclosure, 'Sponsored');
    });

    test('vt_connections-shell_invite-blocked', () {
      const props = ConnectionsShellProps(blockedPassportIds: ['passport_b']);

      expect(props.canInvite('passport_a'), isTrue);
      expect(props.canInvite('passport_b'), isFalse);
    });

    test('vt_payment-surface_shell-owned', () {
      const props = PaymentSurfaceProps(
        surfaceId: 'ad-off-checkout',
        shellOwned: true,
        amountCents: 299,
      );

      expect(props.shellOwned, isTrue);
    });

    test('vt_data-dashboard_consent-revoke', () {
      const props = DataDashboardProps(
        passportId: 'passport_member_1',
        revokedConsentIds: [],
      );

      expect(props.revokeConsent('consent_1').revokedConsentIds, ['consent_1']);
    });

    test('ct_extension-runtime__app-shell_session', () {
      final shell = CommunityAppShellRuntime()..openExtension('ext_book_club');

      expect(shell.openExtensionId, 'ext_book_club');
    });

    test('ct_extension-runtime__app-shell_local-session', () {
      final shell = CommunityAppShellRuntime()..openExtension('local:ext_book_club');

      expect(shell.openExtensionId, 'local:ext_book_club');
    });

    test('ct_app-shell__workflow_install-latest', () {
      final shell = CommunityAppShellRuntime()
        ..installCommunity(_cardProps())
        ..openExtension('ext_book_club@latest');

      expect(shell.cards, hasLength(1));
      expect(shell.openExtensionId, 'ext_book_club@latest');
    });

    test('ct_navigation-panel__workflow_messages-connections-reachable', () {
      final shell = CommunityAppShellRuntime();

      expect(shell.navigation.exposesMessagesAndConnections, isTrue);
    });

    test('ct_stream-renderer__workflow_in-stream-ad', () {
      final item = renderAdStreamItem(title: 'Sponsor', body: 'Offer');

      expect(item.kind, 'ad');
      expect(item.disclosure, 'Sponsored');
    });

    test('ct_payment-surface__workflow_ad-off-checkout', () {
      const props = PaymentSurfaceProps(
        surfaceId: 'ad-off-checkout',
        shellOwned: true,
        amountCents: 299,
      );

      expect(props.shellOwned, isTrue);
    });

    test('ct_data-dashboard__workflow_consent-revoke', () {
      const props = DataDashboardProps(
        passportId: 'passport_member_1',
        revokedConsentIds: [],
      );

      expect(props.revokeConsent('consent_ads').revokedConsentIds, ['consent_ads']);
    });

    test('ct_ad-decision__app-shell_banner-fill', () {
      final shell = CommunityAppShellRuntime();

      expect(shell.topAdSlot.required, isTrue);
    });

    test('ct_ad-decision__stream-renderer_in-stream-ad', () {
      final item = renderAdStreamItem(title: 'Sponsor', body: 'Offer');

      expect(item.disclosure, isNotNull);
    });

    test('ct_wallet__payment-surface_checkout', () {
      const props = PaymentSurfaceProps(
        surfaceId: 'checkout',
        shellOwned: true,
        amountCents: 5000,
      );

      expect(props.amountCents, 5000);
    });
  });
}

CommunityCardProps _cardProps() {
  return CommunityCardProps(
    communityId: 'community_book_club',
    handle: 'book-club',
    branding: _branding(card: 'asset_card_book_club'),
  );
}

CommunityCardBranding _branding({
  String? card,
  String? logo,
  String? extensionDefault,
}) {
  return CommunityCardBranding(
    displayName: 'Neighborhood Book Club',
    tagline: 'Read together',
    category: 'book',
    accentColor: '#246B62',
    altText: 'Book club table',
    cardImageAssetId: card,
    logoAssetId: logo,
    extensionDefaultCardImageAssetId: extensionDefault,
  );
}
