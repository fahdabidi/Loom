part of '../loom_communities_app_shell.dart';

class _RichFact {
  const _RichFact({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

enum _RichWorkflowLayout {
  standard,
  eventDetail,
  formSubmission,
  paymentReceipt,
  rosterProfile,
  requestReview,
  searchAnswer,
  exportWizard,
  messageThread,
  noticeDetail,
  clubScoreboard,
  mediaReview,
  adEntitlement,
}

class _RichWorkflowSpec {
  const _RichWorkflowSpec({
    this.layout = _RichWorkflowLayout.standard,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.facts,
    required this.actionSurfaceTitle,
    required this.actionHeroSubtitle,
    required this.actionHeroBody,
    required this.actionPanelTitle,
    required this.actionPanelBody,
    required this.alternateActionLabel,
    required this.detailTitle,
    required this.detailRows,
    required this.stateTitle,
    required this.stateRows,
    required this.completeTitle,
    required this.completeBody,
    required this.receivedTitle,
    required this.receivedBody,
    required this.completeLabel,
  });

  final _RichWorkflowLayout layout;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final List<_RichFact> facts;
  final String actionSurfaceTitle;
  final String actionHeroSubtitle;
  final String actionHeroBody;
  final String actionPanelTitle;
  final String actionPanelBody;
  final String alternateActionLabel;
  final String detailTitle;
  final List<_ActionSurfaceDetail> detailRows;
  final String stateTitle;
  final List<_ActionSurfaceDetail> stateRows;
  final String completeTitle;
  final String completeBody;
  final String receivedTitle;
  final String receivedBody;
  final String completeLabel;
}

_RichWorkflowSpec? _richWorkflowSpecFor(
  String workflowId, {
  LoomWorkflowDefinition? workflow,
  Color fallbackAccent = const Color(0xff246b62),
}) {
  switch (workflowId) {
    case 'garden-export-custom-schemas':
      return const _RichWorkflowSpec(
        accent: Color(0xff376f57),
        icon: Icons.folder_zip_outlined,
        title: 'Garden data export package',
        subtitle: 'Choose event and plant-exchange data before download.',
        body:
            'Export scope includes garden_event and plant_exchange schemas with protected contact fields redacted.',
        facts: [
          _RichFact(icon: Icons.dataset_outlined, label: '2 schemas selected'),
          _RichFact(
            icon: Icons.visibility_off_outlined,
            label: 'Redaction preview',
          ),
          _RichFact(icon: Icons.verified_outlined, label: 'Checksum verified'),
          _RichFact(icon: Icons.download_outlined, label: 'Download ready'),
        ],
        actionSurfaceTitle: 'Garden export package',
        actionHeroSubtitle: 'garden_event + plant_exchange',
        actionHeroBody:
            'Confirm selected data, protected-field redaction, checksum, and destination before generating the export.',
        actionPanelTitle: 'Export package checkpoint',
        actionPanelBody:
            'The package will include event attendance, plant offers, redacted member contact fields, and an audit checksum.',
        alternateActionLabel: 'Change scope',
        detailTitle: 'Package contents',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.dataset_outlined,
            title: 'Scope',
            body:
                'Selected data: garden_event, plant_exchange, RSVP choice, offer status, and export metadata.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Redaction preview',
            body:
                'Member phone, address, and private pickup notes are protected before transfer.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Checksum',
            body:
                'Checksum 8F4A-PLANT verifies the package and appears in the audit trail.',
          ),
        ],
        stateTitle: 'Transfer record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.download_outlined,
            title: 'Destination',
            body:
                'Download to owner device first; provider transfer remains disabled until owner confirms.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Rollback',
            body:
                'Change scope or cancel export before the package is generated.',
          ),
        ],
        completeTitle: 'Export generated',
        completeBody:
            'Garden Club export is ready with redaction preview, checksum 8F4A-PLANT, and download progress.',
        receivedTitle: 'Export progress ready',
        receivedBody:
            'The owner can open export scope, redaction, checksum, and transfer progress.',
        completeLabel: 'Exported',
      );
    case 'book-nomination':
      return const _RichWorkflowSpec(
        accent: Color(0xff5f4b8b),
        icon: Icons.menu_book_outlined,
        title: 'Nominate Parable of the Sower',
        subtitle: 'Octavia E. Butler - February reading cycle.',
        body:
            'Share why this title belongs on the ballot and how it fits the upcoming discussion.',
        facts: [
          _RichFact(icon: Icons.title_outlined, label: 'Book title entered'),
          _RichFact(icon: Icons.person_outline, label: 'Author confirmed'),
          _RichFact(icon: Icons.forum_outlined, label: 'Discussion reason'),
          _RichFact(icon: Icons.how_to_vote_outlined, label: 'Ballot eligible'),
        ],
        actionSurfaceTitle: 'Book nomination',
        actionHeroSubtitle: 'Parable of the Sower by Octavia E. Butler',
        actionHeroBody:
            'Confirm the title, author, member rationale, genre, and meeting cycle before submitting the nomination.',
        actionPanelTitle: 'Nomination details',
        actionPanelBody:
            'The nomination will be visible to members for the February vote and tied to the discussion meeting.',
        alternateActionLabel: 'Edit nomination',
        detailTitle: 'Nomination details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.title_outlined,
            title: 'Title and author',
            body: 'Parable of the Sower - Octavia E. Butler.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.lightbulb_outline,
            title: 'Member rationale',
            body:
                'Chosen for a timely discussion on resilience, community, and care.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.event_outlined,
            title: 'Meeting cycle',
            body: 'February vote, March living-room discussion.',
          ),
        ],
        stateTitle: 'Ballot record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.how_to_vote_outlined,
            title: 'Vote connection',
            body:
                'After submission, members can compare nominations and cast one vote.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.edit_note_outlined,
            title: 'Change option',
            body:
                'Edit nomination details before voting opens or withdraw if the title is no longer available.',
          ),
        ],
        completeTitle: 'Nomination submitted',
        completeBody:
            'Parable of the Sower is on the February ballot with title, author, rationale, and meeting context.',
        receivedTitle: 'Nomination ready',
        receivedBody:
            'Members can read the nomination, compare vote options, and prepare for discussion.',
        completeLabel: 'Submitted',
      );
    case 'book-vote':
      return const _RichWorkflowSpec(
        accent: Color(0xff4e5fa8),
        icon: Icons.how_to_vote_outlined,
        title: 'February book ballot',
        subtitle: 'Vote between three member nominations.',
        body:
            'Parable of the Sower is leading the ballot for the next monthly discussion.',
        facts: [
          _RichFact(icon: Icons.menu_book_outlined, label: '3 nominations'),
          _RichFact(icon: Icons.schedule_outlined, label: 'Closes Jan 20'),
          _RichFact(icon: Icons.how_to_vote_outlined, label: '1 member vote'),
          _RichFact(icon: Icons.star_outline, label: 'Leading title'),
        ],
        actionSurfaceTitle: 'Cast book vote',
        actionHeroSubtitle: 'February selection ballot',
        actionHeroBody:
            'Compare nominated books, confirm your vote, and keep the chosen discussion book visible after voting.',
        actionPanelTitle: 'Ballot choice',
        actionPanelBody:
            'Your vote will count once for Parable of the Sower and can be changed before the ballot closes.',
        alternateActionLabel: 'Change vote',
        detailTitle: 'Ballot options',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Parable of the Sower',
            body: 'Current leader with 9 votes and a member discussion note.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'The Memory Police',
            body: 'Second place with 6 votes.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Braiding Sweetgrass',
            body: 'Third place with 5 votes.',
          ),
        ],
        stateTitle: 'Vote saved',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Vote state',
            body: 'Your selected book and vote timestamp remain visible.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.swap_horiz_outlined,
            title: 'Change option',
            body: 'Change vote remains available until Jan 20 at 8 PM.',
          ),
        ],
        completeTitle: 'Vote confirmed',
        completeBody:
            'Your vote for Parable of the Sower is confirmed, status is saved, and it can be changed before the ballot closes.',
        receivedTitle: 'Vote result ready',
        receivedBody:
            'The selected book, vote count, and meeting context are visible to members.',
        completeLabel: 'Voted',
      );
    case 'book-meeting-rsvp':
      return const _RichWorkflowSpec(
        accent: Color(0xff2f6f9f),
        icon: Icons.event_available_outlined,
        title: 'Parable discussion night',
        subtitle: 'Thu, Feb 15 at 7:00 PM - Maya\'s living room.',
        body:
            'Reserve a seat for the discussion and see host, location, capacity, and reminder status.',
        facts: [
          _RichFact(icon: Icons.calendar_today_outlined, label: 'Thu, Feb 15'),
          _RichFact(icon: Icons.schedule_outlined, label: '7:00 PM'),
          _RichFact(icon: Icons.place_outlined, label: 'Maya\'s living room'),
          _RichFact(icon: Icons.group_outlined, label: '10 of 14 spots'),
        ],
        actionSurfaceTitle: 'Book meeting RSVP',
        actionHeroSubtitle: 'Parable of the Sower discussion',
        actionHeroBody:
            'Confirm the meeting title, date, venue, host, capacity, and current RSVP before saving your response.',
        actionPanelTitle: 'Choose attendance',
        actionPanelBody:
            'Going reserves a seat and sends a reminder. Maybe keeps the meeting on your calendar without taking capacity.',
        alternateActionLabel: 'Change response',
        detailTitle: 'Meeting details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Host',
            body: 'Maya Chen hosts the February discussion.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Selected book',
            body: 'Parable of the Sower by Octavia E. Butler.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.group_outlined,
            title: 'Capacity',
            body: '10 attending, 4 seats open, waitlist starts at 14.',
          ),
        ],
        stateTitle: 'Response options',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Going',
            body: 'Reserve a seat and add a reminder to your inbox.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.help_outline,
            title: 'Maybe or not attending',
            body: 'Change response or release your seat before the meeting.',
          ),
        ],
        completeTitle: 'RSVP confirmed',
        completeBody:
            'You are going to the Parable discussion; seat count, reminder, and change response stay visible.',
        receivedTitle: 'Meeting update ready',
        receivedBody:
            'The meeting page shows book, date, venue, capacity, and your RSVP choice.',
        completeLabel: 'Going',
      );
    case 'book-discussion-message':
      return const _RichWorkflowSpec(
        accent: Color(0xff6f4e7c),
        icon: Icons.forum_outlined,
        title: 'Discussion thread',
        subtitle: 'Prompt: What does community care require?',
        body:
            'Reply to the Parable discussion with a note scoped to club members.',
        facts: [
          _RichFact(icon: Icons.person_outline, label: 'From Jordan'),
          _RichFact(icon: Icons.group_outlined, label: 'Members only'),
          _RichFact(icon: Icons.mark_email_unread_outlined, label: '3 unread'),
          _RichFact(icon: Icons.lock_outline, label: 'Club scoped'),
        ],
        actionSurfaceTitle: 'Reply to discussion',
        actionHeroSubtitle: 'Parable discussion thread',
        actionHeroBody:
            'Read the prompt, sender, audience, and member replies before posting your discussion note.',
        actionPanelTitle: 'Message delivery',
        actionPanelBody:
            'Your reply will appear in the club thread and stay scoped to current members.',
        alternateActionLabel: 'Archive thread',
        detailTitle: 'Thread context',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.question_answer_outlined,
            title: 'Prompt',
            body: 'What does community care require when resources are scarce?',
          ),
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Latest sender',
            body: 'Jordan posted a discussion-prep message this morning.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.message_outlined,
            title: 'Message body',
            body: 'Bring one quote that changed how you read the ending.',
          ),
        ],
        stateTitle: 'Conversation record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.reply_outlined,
            title: 'Reply option',
            body: 'Reply, mute, archive, or return later without losing place.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.lock_outline,
            title: 'Privacy',
            body: 'Only active book club members can read or reply.',
          ),
        ],
        completeTitle: 'Reply sent',
        completeBody:
            'Your discussion message is posted to the Parable thread with sender and member scope.',
        receivedTitle: 'Thread updated',
        receivedBody:
            'Members see sender, message body, unread receipt, and reply action.',
        completeLabel: 'Sent',
      );
    case 'book-selection-publish':
      return const _RichWorkflowSpec(
        accent: Color(0xff286b5f),
        icon: Icons.campaign_outlined,
        title: 'Publish February selection',
        subtitle: 'Parable of the Sower won the member vote.',
        body:
            'Send the selected-book announcement with audience, author, message body, and delivery timing.',
        facts: [
          _RichFact(icon: Icons.group_outlined, label: 'Audience: members'),
          _RichFact(icon: Icons.person_outline, label: 'From organizer'),
          _RichFact(icon: Icons.today_outlined, label: 'Today 5:00 PM'),
          _RichFact(icon: Icons.inbox_outlined, label: 'Inbox + push'),
        ],
        actionSurfaceTitle: 'Selection announcement',
        actionHeroSubtitle: 'February book: Parable of the Sower',
        actionHeroBody:
            'Preview the announcement body, sender, audience, delivery time, and member inbox preview before publishing.',
        actionPanelTitle: 'Announcement publish details',
        actionPanelBody:
            'Members will receive the selected book, meeting date, and discussion prompt in their inbox.',
        alternateActionLabel: 'Save draft',
        detailTitle: 'Announcement preview',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Sender',
            body: 'From Maya, Book Club Organizer.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.message_outlined,
            title: 'Message body',
            body:
                'February selection: Parable of the Sower. Meeting details and reading prompt are ready.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.schedule_outlined,
            title: 'Delivery',
            body: 'Send today at 5:00 PM to all active members.',
          ),
        ],
        stateTitle: 'Member inbox result',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.inbox_outlined,
            title: 'Member inbox',
            body:
                'Members can read the selection and jump to RSVP or discussion.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.edit_note_outlined,
            title: 'Draft option',
            body: 'Preview announcement or save draft before publishing.',
          ),
        ],
        completeTitle: 'Selection published',
        completeBody:
            'Members received the February selection announcement with book, sender, timing, and next steps.',
        receivedTitle: 'Selection ready',
        receivedBody:
            'The member inbox shows the selected book, meeting date, and discussion prompt.',
        completeLabel: 'Published',
      );
    case 'book-search-ai-digest':
      return const _RichWorkflowSpec(
        layout: _RichWorkflowLayout.searchAnswer,
        accent: Color(0xff3f5f8f),
        icon: Icons.manage_search_outlined,
        title: 'Reading guide answer',
        subtitle: 'Query: "What should we discuss before chapter 6?"',
        body:
            'Confirm the AI answer, quoted source snippets, citation list, and follow-up prompts before saving it to the club digest.',
        facts: [
          _RichFact(icon: Icons.search_outlined, label: 'Question asked'),
          _RichFact(icon: Icons.auto_awesome_outlined, label: 'AI summary'),
          _RichFact(icon: Icons.format_quote_outlined, label: '3 citations'),
          _RichFact(icon: Icons.bookmark_border_outlined, label: 'Save digest'),
        ],
        actionSurfaceTitle: 'Reading guide answer',
        actionHeroSubtitle:
            'Parable of the Sower reading guide with cited sources',
        actionHeroBody:
            'Confirm the query, answer summary, citation snippets, source titles, and follow-up action before saving the digest.',
        actionPanelTitle: 'Reading guide save details',
        actionPanelBody:
            'The digest will save the answer, source citations, and suggested discussion prompts for members.',
        alternateActionLabel: 'Ask follow-up',
        detailTitle: 'Answer and citations',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.auto_awesome_outlined,
            title: 'Answer summary',
            body:
                'Focus the chapter 6 discussion on mutual aid, scarcity, and Lauren\'s journal voice.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.format_quote_outlined,
            title: 'Source snippets',
            body:
                'Cites member notes, the February nomination rationale, and the March discussion prompt.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.library_books_outlined,
            title: 'Citation detail',
            body:
                'Each citation shows source title, author or member, and why it is visible to this member.',
          ),
        ],
        stateTitle: 'Digest state',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.bookmark_border_outlined,
            title: 'Saved guide',
            body:
                'Members can reopen the cited answer, share it to the discussion, or ask a follow-up.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Source visibility',
            body:
                'Private member notes stay hidden; visible citations show permission-safe source labels.',
          ),
        ],
        completeTitle: 'Guide saved',
        completeBody:
            'The reading guide now shows query, answer, citations, source visibility, save state, and follow-up prompts.',
        receivedTitle: 'Guide ready',
        receivedBody:
            'Members can read the AI summary, open citations, and open the discussion prompt.',
        completeLabel: 'Saved',
      );
    case 'book-export-metadata':
      return const _RichWorkflowSpec(
        layout: _RichWorkflowLayout.exportWizard,
        accent: Color(0xff536878),
        icon: Icons.folder_zip_outlined,
        title: 'Book club export package',
        subtitle: 'Nominations, votes, RSVPs, threads, and reading schedule.',
        body:
            'Select book-club data, member-message redaction, checksum, download, and audit history before exporting.',
        facts: [
          _RichFact(icon: Icons.menu_book_outlined, label: 'Books + ballots'),
          _RichFact(icon: Icons.forum_outlined, label: 'Threads redacted'),
          _RichFact(icon: Icons.verified_outlined, label: 'Checksum BC-042'),
          _RichFact(icon: Icons.download_outlined, label: 'Download ready'),
        ],
        actionSurfaceTitle: 'Book club export package',
        actionHeroSubtitle: 'Portable reading-club archive',
        actionHeroBody:
            'Confirm nominations, ballots, meeting RSVPs, discussion threads, redaction preview, checksum, and download destination.',
        actionPanelTitle: 'Archive package',
        actionPanelBody:
            'The archive includes book nominations, vote history, meeting RSVPs, reading schedule, discussion messages, and redacted member contact fields.',
        alternateActionLabel: 'Change export scope',
        detailTitle: 'Archive contents',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Reading data',
            body:
                'Nominations, selected books, ballot counts, reading schedule, and meeting RSVP records.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Redaction preview',
            body:
                'Member email, phone, and private thread metadata are redacted unless the owner has consent.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Checksum and audit',
            body:
                'Checksum BC-042 and export timestamp are written to the owner audit history.',
          ),
        ],
        stateTitle: 'Archive record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.file_download_outlined,
            title: 'Download',
            body:
                'Owner can download the archive after checksum verification succeeds.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Rollback',
            body:
                'Change scope or cancel before export generation; previous exports stay in audit history.',
          ),
        ],
        completeTitle: 'Book archive generated',
        completeBody:
            'Book club export shows reading data, redaction preview, checksum BC-042, download progress, and audit trail.',
        receivedTitle: 'Export archive ready',
        receivedBody:
            'Owner can open the archive contents, checksum, and redaction evidence.',
        completeLabel: 'Exported',
      );
    case 'mosque-announcement':
      return const _RichWorkflowSpec(
        accent: Color(0xff2d6a4f),
        icon: Icons.campaign_outlined,
        title: 'Ramadan community night',
        subtitle: 'Announcement composer for Masjid Nur members.',
        body:
            'Confirm the message body, selected audience, sender, delivery timing, and member inbox preview before publishing.',
        facts: [
          _RichFact(icon: Icons.group_outlined, label: 'Audience: members'),
          _RichFact(icon: Icons.person_outline, label: 'From Masjid Admin'),
          _RichFact(icon: Icons.schedule_outlined, label: 'Today 6:00 PM'),
          _RichFact(icon: Icons.inbox_outlined, label: 'Inbox + push'),
        ],
        actionSurfaceTitle: 'Publish announcement',
        actionHeroSubtitle: 'Ramadan community night - Friday after Maghrib',
        actionHeroBody:
            'Send a respectful community update with event time, volunteer note, audience, and delivery channel.',
        actionPanelTitle: 'Publish details',
        actionPanelBody:
            'Members will receive the announcement in their inbox and notification list with read receipt.',
        alternateActionLabel: 'Preview announcement',
        detailTitle: 'Announcement preview',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.message_outlined,
            title: 'Message body',
            body:
                'Join Ramadan community night after Maghrib. Iftar setup volunteers arrive at 5:30 PM.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Sender',
            body: 'Masjid Admin, community announcements.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.group_outlined,
            title: 'Audience',
            body: 'All active members; donors and care volunteers included.',
          ),
        ],
        stateTitle: 'Delivery and member inbox',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.schedule_outlined,
            title: 'Delivery',
            body: 'Send today at 6:00 PM through inbox and push notification.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.mark_email_read_outlined,
            title: 'Member inbox preview',
            body:
                'Members can read the posted announcement and see it as received.',
          ),
        ],
        completeTitle: 'Announcement posted',
        completeBody:
            'Members can read the Ramadan community night update in their inbox with sender, audience, and delivery time.',
        receivedTitle: 'Update ready',
        receivedBody:
            'The member inbox shows sender, message body, audience, delivery timing, and read receipt.',
        completeLabel: 'Sent',
      );
    case 'mosque-event-rsvp':
      return const _RichWorkflowSpec(
        accent: Color(0xff2f6f9f),
        icon: Icons.event_available_outlined,
        title: 'Community iftar RSVP',
        subtitle: 'Fri, Mar 14 at 6:45 PM - Fellowship hall.',
        body:
            'Reserve a seat after checking event time, location, host, capacity, and reminder details.',
        facts: [
          _RichFact(icon: Icons.calendar_today_outlined, label: 'Fri, Mar 14'),
          _RichFact(icon: Icons.schedule_outlined, label: '6:45 PM'),
          _RichFact(icon: Icons.place_outlined, label: 'Fellowship hall'),
          _RichFact(icon: Icons.group_outlined, label: '86 of 120 spots'),
        ],
        actionSurfaceTitle: 'Iftar RSVP',
        actionHeroSubtitle: 'Ramadan community iftar',
        actionHeroBody:
            'Confirm the date, time, location, capacity, and family attendance before saving your response.',
        actionPanelTitle: 'Choose RSVP response',
        actionPanelBody:
            'Going reserves a spot; maybe keeps the event visible without taking capacity; not attending releases your seat.',
        alternateActionLabel: 'Change response',
        detailTitle: 'Event details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Host',
            body: 'Masjid Nur community team.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.group_outlined,
            title: 'Capacity',
            body: '86 attending, 34 spots available.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.place_outlined,
            title: 'Location',
            body: 'Fellowship hall, west entrance after Maghrib.',
          ),
        ],
        stateTitle: 'Response options',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Going',
            body: 'Reserve a seat and receive a reminder before Maghrib.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.swap_horiz_outlined,
            title: 'Change later',
            body: 'Change response or release your seat if plans change.',
          ),
        ],
        completeTitle: 'RSVP confirmed',
        completeBody:
            'Your iftar RSVP is confirmed with date, time, location, capacity, and reminder state visible.',
        receivedTitle: 'Iftar update ready',
        receivedBody:
            'The event page shows attendance choice, capacity, and any schedule changes.',
        completeLabel: 'Going',
      );
    case 'mosque-volunteer-signup':
      return const _RichWorkflowSpec(
        accent: Color(0xff3f7f4c),
        icon: Icons.volunteer_activism_outlined,
        title: 'Iftar setup shift',
        subtitle: 'Friday 4:30 PM - tables, check-in, and meal handoff.',
        body:
            'Choose the role, confirm shift time, protect contact details, and confirm coordinator follow-up.',
        facts: [
          _RichFact(
            icon: Icons.volunteer_activism_outlined,
            label: 'Setup role',
          ),
          _RichFact(icon: Icons.schedule_outlined, label: '4:30-6:30 PM shift'),
          _RichFact(icon: Icons.phone_outlined, label: 'Phone protected'),
          _RichFact(icon: Icons.group_outlined, label: '2 spots open'),
        ],
        actionSurfaceTitle: 'Volunteer signup',
        actionHeroSubtitle: 'Iftar setup team',
        actionHeroBody:
            'Confirm shift role, time, location, contact preference, and coordinator handoff before signing up.',
        actionPanelTitle: 'Shift signup details',
        actionPanelBody:
            'Your protected phone is shared only with the volunteer coordinator after confirmation.',
        alternateActionLabel: 'Edit availability',
        detailTitle: 'Shift details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.task_alt_outlined,
            title: 'Volunteer task',
            body: 'Set up tables, check-in labels, and meal handoff station.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.schedule_outlined,
            title: 'Time and place',
            body: 'Friday 4:30-6:30 PM, fellowship hall west entrance.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.phone_outlined,
            title: 'Protected contact',
            body: 'Phone is visible only to the volunteer coordinator.',
          ),
        ],
        stateTitle: 'Signup record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Confirmation',
            body:
                'Coordinator receives your signup and protected contact preference.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.edit_note_outlined,
            title: 'Change option',
            body: 'Edit availability or cancel the shift if plans change.',
          ),
        ],
        completeTitle: 'Volunteer signup confirmed',
        completeBody:
            'You are signed up for iftar setup with protected phone, shift time, role, and coordinator follow-up.',
        receivedTitle: 'Volunteer update ready',
        receivedBody:
            'The coordinator sees role, shift, protected contact state, and signup confirmation.',
        completeLabel: 'Signed up',
      );
  }
  return _fallbackRichWorkflowSpecFor(
    workflowId,
    workflow: workflow,
    fallbackAccent: fallbackAccent,
  );
}

_RichWorkflowSpec _fallbackRichWorkflowSpecFor(
  String workflowId, {
  LoomWorkflowDefinition? workflow,
  Color fallbackAccent = const Color(0xff246b62),
}) {
  final id = workflowId.toLowerCase();
  if (id.startsWith('soccer-')) {
    return _soccerRichSpecFor(id);
  }
  if (id.startsWith('hoa-')) {
    return _hoaRichSpecFor(id);
  }
  if (id.startsWith('mosque-')) {
    return _mosqueRichSpecFor(id);
  }
  if (id.startsWith('book-') && id.contains('export')) {
    return _exportRichSpecFor(id);
  }
  if (id.startsWith('chess-')) {
    return _chessRichSpecFor(id);
  }
  if (id.startsWith('photo-') ||
      id.startsWith('critique-') ||
      id.startsWith('gear-')) {
    return _cameraRichSpecFor(id);
  }
  if (id.startsWith('platform-')) {
    return _platformRichSpecFor(id);
  }
  if (id.startsWith('ad-off-')) {
    return _adOffRichSpecFor(id);
  }
  if (id.startsWith('export-')) {
    return _exportRichSpecFor(id);
  }
  // No bespoke rich-spec entry exists for this workflow (true for every
  // package-driven workflow whose id doesn't collide with a hardcoded demo
  // prefix). Use the workflow's own declared copy instead of generic
  // placeholder text, so this card shows the same title/description as the
  // rest of the app (minimized surface, action surface) instead of an
  // unrelated "Community item" label that made minimized -> focused
  // transitions look like the card had switched to something else.
  final title = workflow?.title ?? 'Community item';
  final entryText =
      workflow?.entryText ?? 'Details, action, and result are ready.';
  final actionText = workflow?.actionText ?? 'Confirm this item to continue.';
  final resultText =
      workflow?.resultText ?? 'Saved with a visible result and next steps.';
  return _richSurface(
    // Force the plain layout instead of the keyword-based
    // _inferredRichWorkflowLayout heuristic below: that heuristic exists to
    // pick a bespoke "look" for the curated catalog's hand-written specs,
    // but package-declared titles are arbitrary free text (e.g. "RSVP to
    // Friday game night" contains "rsvp") and would get swept into a
    // bespoke layout that doesn't know about responseChoices/calendarItem/
    // any other Phase 2 mechanism this fallback needs to support.
    layout: _RichWorkflowLayout.standard,
    accent: fallbackAccent,
    icon: Icons.apps_outlined,
    title: title,
    // The tile shows title/subtitle/body as three stacked lines, so
    // subtitle and body must carry different copy or the same sentence
    // renders twice. actionText ("Reserve a seat...") reads as the tile's
    // call-to-action line above entryText's fuller detail paragraph.
    subtitle: actionText,
    body: entryText,
    // The action-surface hero panel pairs subtitle+body the other way
    // around (context line, then the call-to-action body) — set explicitly
    // since the _richSurface default for actionHeroSubtitle is `subtitle`,
    // which is now actionText and would otherwise duplicate actionHeroBody.
    actionHeroSubtitle: entryText,
    actionHeroBody: actionText,
    actionPanelBody: actionText,
    completeBody: resultText,
    receivedBody: resultText,
    facts: const [
      _RichFact(icon: Icons.assignment_outlined, label: 'Details ready'),
      _RichFact(icon: Icons.edit_note_outlined, label: 'Editable'),
      _RichFact(icon: Icons.verified_outlined, label: 'State saved'),
    ],
    detailTitle: 'Activity details',
    detailRows: [
      _ActionSurfaceDetail(
        icon: Icons.assignment_outlined,
        title: 'Context',
        body: entryText,
      ),
      const _ActionSurfaceDetail(
        icon: Icons.edit_note_outlined,
        title: 'Change option',
        body: 'The member can save, edit, cancel, or return later.',
      ),
    ],
    stateTitle: 'Saved details',
    stateRows: [
      _ActionSurfaceDetail(
        icon: Icons.task_alt_outlined,
        title: 'Result',
        body: resultText,
      ),
    ],
  );
}

_RichWorkflowSpec _soccerRichSpecFor(String id) {
  if (id.contains('guardian-join')) {
    return _richSurface(
      accent: const Color(0xff1f7a5c),
      icon: Icons.family_restroom_outlined,
      title: 'Guardian approval desk',
      subtitle: 'Mia Rivera requests access for U10 Falcons.',
      body:
          'Confirm guardian identity, player connection, emergency-contact status, and approval notes before activating membership.',
      facts: const [
        _RichFact(icon: Icons.person_outline, label: 'Mia Rivera'),
        _RichFact(icon: Icons.sports_soccer_outlined, label: 'U10 Falcons'),
        _RichFact(
          icon: Icons.health_and_safety_outlined,
          label: 'Emergency contact',
        ),
        _RichFact(icon: Icons.task_alt_outlined, label: 'Approve or reject'),
      ],
      actionPanelTitle: 'Coach approval details',
      actionPanelBody:
          'Approve guardian access, request changes, or reject with a private note that the guardian can read.',
      alternateActionLabel: 'Request changes',
      detailTitle: 'Guardian request',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Guardian',
          body:
              'Mia Rivera, parent of Leo Rivera, requested U10 Falcons access today.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.shield_outlined,
          title: 'Safety info',
          body:
              'Emergency contact and pickup authorization are present for coach action.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.comment_outlined,
          title: 'Decision note',
          body:
              'Coach can approve, reject, or ask for a missing waiver before activation.',
        ),
      ],
      stateTitle: 'Decision recorded',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.verified_user_outlined,
          title: 'Membership state',
          body:
              'Approved guardians see team schedule, roster, fees, and reminders.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.history_outlined,
          title: 'Outcome history',
          body: 'The request keeps reviewer, timestamp, and decision history.',
        ),
      ],
      completeTitle: 'Guardian approved',
      completeBody:
          'Mia Rivera is active for U10 Falcons with player link, emergency-contact status, and decision history visible.',
      completeLabel: 'Approved',
    );
  }
  if (id.contains('team-roster')) {
    return _richSurface(
      accent: const Color(0xff276f8f),
      icon: Icons.groups_outlined,
      title: 'U10 Falcons roster',
      subtitle: '12 players, 9 guardians, 2 missing waivers.',
      body:
          'Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details.',
      facts: const [
        _RichFact(icon: Icons.group_outlined, label: '12 players'),
        _RichFact(icon: Icons.assignment_late_outlined, label: '2 waivers due'),
        _RichFact(
          icon: Icons.visibility_off_outlined,
          label: 'Birthdates protected',
        ),
        _RichFact(icon: Icons.mail_outline, label: 'Guardian contacts'),
      ],
      actionPanelTitle: 'Roster ready to open',
      actionPanelBody:
          'Open roster details, update team notes, message guardians, or export a protected team sheet.',
      alternateActionLabel: 'Message guardians',
      detailTitle: 'Roster details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Featured player',
          body:
              'Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.lock_outline,
          title: 'Protected fields',
          body:
              'Birthdates and medical notes are redacted unless the coach has permission.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.sports_soccer_outlined,
          title: 'Team context',
          body: 'U10 Falcons practice Saturday at Riverside Field 3.',
        ),
      ],
      stateTitle: 'Coach actions',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.edit_note_outlined,
          title: 'Update roster',
          body:
              'Coach can add notes, track missing waivers, and export a protected roster.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.notifications_outlined,
          title: 'Guardian follow-up',
          body: 'Message only guardians with incomplete forms.',
        ),
      ],
      completeTitle: 'Roster opened',
      completeBody:
          'The U10 Falcons roster shows players, guardians, waiver status, and protected-field handling.',
      completeLabel: 'Opened',
    );
  }
  if (id.contains('payment')) {
    return _richSurface(
      accent: const Color(0xff6d4aa2),
      icon: Icons.receipt_long_outlined,
      title: 'Season registration fee',
      subtitle: '125.00 USD for Leo Rivera - U10 Falcons.',
      body:
          'Confirm payer, player, season fee, receipt destination, retry option, and scholarship note before payment.',
      facts: const [
        _RichFact(icon: Icons.attach_money, label: '125.00 USD'),
        _RichFact(icon: Icons.person_outline, label: 'Leo Rivera'),
        _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt saved'),
        _RichFact(icon: Icons.privacy_tip_outlined, label: 'Private payer'),
      ],
      actionPanelTitle: 'Payment summary',
      actionPanelBody:
          'Pay dues, change payer details, retry a failed payment, or open the receipt after confirmation.',
      alternateActionLabel: 'Change payer',
      detailTitle: 'Payment details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.sports_soccer_outlined,
          title: 'Registration',
          body: 'U10 Falcons spring season registration for Leo Rivera.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt',
          body:
              'Receipt goes to guardian account and appears in payment history.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.help_outline,
          title: 'Support',
          body: 'Scholarship note can be reviewed before checkout.',
        ),
      ],
      stateTitle: 'Receipt created',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.check_circle_outline,
          title: 'Entitlement',
          body: 'Player registration status changes to paid and active.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.refresh_outlined,
          title: 'Retry option',
          body: 'Failed payments can be retried without losing form state.',
        ),
      ],
      completeTitle: 'Registration paid',
      completeBody:
          'Leo Rivera registration is paid with receipt, payer, season, and status visible.',
      completeLabel: 'Paid',
    );
  }
  return _richSurface(
    accent: const Color(0xff1f7a5c),
    icon: id.contains('schedule') || id.contains('reminder')
        ? Icons.event_available_outlined
        : Icons.privacy_tip_outlined,
    title: id.contains('schedule')
        ? 'Saturday practice schedule'
        : id.contains('reminder')
        ? 'Guardian practice reminder'
        : id.contains('export')
        ? 'Protected soccer export'
        : 'Youth privacy record',
    subtitle: id.contains('schedule')
        ? 'Sat 9:00 AM - Riverside Field 3, U10 Falcons.'
        : id.contains('reminder')
        ? 'Practice starts at 9:00 AM, field and gear note included.'
        : 'Roster and registration data with minor protection.',
    body: id.contains('schedule')
        ? 'Publish team schedule details with time, field, capacity, guardian inbox preview, and confirmed attendance result.'
        : id.contains('reminder')
        ? 'Send the reminder message body with sender, guardian audience, timestamp, and inbox channel.'
        : id.contains('export')
        ? 'Show protected roster scope, redaction preview, checksum verification, transfer progress, and guardian or coach visibility.'
        : 'Show protected minor data, redaction result, export scope, and permission boundaries for coaches and guardians.',
    facts: const [
      _RichFact(icon: Icons.schedule_outlined, label: 'Saturday 9 AM'),
      _RichFact(icon: Icons.place_outlined, label: 'Field 3'),
      _RichFact(icon: Icons.event_available_outlined, label: 'RSVP available'),
      _RichFact(icon: Icons.visibility_off_outlined, label: 'Protected data'),
      _RichFact(icon: Icons.verified_outlined, label: 'Checksum verified'),
    ],
    actionPanelTitle: 'Publish details',
    actionPanelBody:
        'Confirm time, field, recipient guardians, protected details, and inbox preview before saving.',
    alternateActionLabel: 'Edit details',
    detailTitle: 'Team details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.sports_soccer_outlined,
        title: 'Team',
        body: 'U10 Falcons, coach Jordan Patel, 12-player roster.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.schedule_outlined,
        title: 'Schedule',
        body:
            'Saturday practice at 9:00 AM on Riverside Field 3 with RSVP and attendance result visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.visibility_off_outlined,
        title: 'Privacy',
        body:
            'Minor profile fields are redacted for guardians and visible to coaches only where permitted.',
      ),
    ],
    stateTitle: 'Recipient result',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.notifications_outlined,
        title: 'Guardian update',
        body:
            'Guardians receive schedule, roster-safe details, reminder message body, timestamp, and inbox channel.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.file_download_outlined,
        title: 'Export state',
        body:
            'Protected export includes roster metadata, redaction preview, checksum verification, and transfer progress.',
      ),
    ],
    completeTitle: 'Team update saved',
    completeBody:
        'The soccer update shows RSVP choice, reminder body, checksum or saved result, inbox preview, and protected data handling.',
    completeLabel: 'Saved',
  );
}

_RichWorkflowSpec _hoaRichSpecFor(String id) {
  final isPayment = id.contains('dues') || id.contains('facility');
  final isDocument = id.contains('document');
  final isApproval =
      id.contains('architectural') ||
      id.contains('committee') ||
      id.contains('notification');
  if (id.contains('notification')) {
    return _richSurface(
      layout: _RichWorkflowLayout.noticeDetail,
      accent: const Color(0xff3e6b8f),
      icon: Icons.mark_email_read_outlined,
      title: 'Owner decision notice',
      subtitle: 'Lot 42 fence request - approved with conditions.',
      body:
          'Send the owner notice with board sender, decision summary, required paint condition, delivery time, and owner inbox state.',
      facts: const [
        _RichFact(icon: Icons.home_outlined, label: 'Lot 42'),
        _RichFact(icon: Icons.person_outline, label: 'From HOA Board'),
        _RichFact(icon: Icons.schedule_outlined, label: 'Today 4:15 PM'),
        _RichFact(icon: Icons.inbox_outlined, label: 'Owner inbox'),
      ],
      actionSurfaceTitle: 'Send owner notice',
      actionHeroSubtitle: 'Avery Brooks - architectural decision',
      actionHeroBody:
          'Confirm sender, recipient, decision body, condition, timestamp, and homeowner inbox preview before sending.',
      actionPanelTitle: 'Owner notification details',
      actionPanelBody:
          'The owner receives the board decision, condition, appeal/reopen option, and message timestamp in their inbox.',
      alternateActionLabel: 'Edit notice',
      detailTitle: 'Notice message',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Sender and recipient',
          body:
              'From Cedar Commons HOA Board to Avery Brooks, homeowner for Lot 42.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.message_outlined,
          title: 'Message body',
          body:
              'Your slate gray fence repaint is approved if trim remains cedar and work starts within 30 days.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.schedule_outlined,
          title: 'Delivery',
          body: 'Send today at 4:15 PM to owner inbox and email receipt.',
        ),
      ],
      stateTitle: 'Homeowner inbox preview',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.inbox_outlined,
          title: 'Owner inbox',
          body:
              'Owner sees decision, sender, message body, timestamp, condition, and appeal option.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.undo_outlined,
          title: 'Follow-up',
          body:
              'Owner can appeal, request clarification, or reopen with a revised color sample.',
        ),
      ],
      completeTitle: 'Owner notified',
      completeBody:
          'Owner notice shows sender, recipient, body, timestamp, decision condition, inbox receipt, and follow-up option.',
      receivedTitle: 'Decision notice received',
      receivedBody:
          'The homeowner inbox shows the board sender, decision body, timestamp, condition, and appeal option.',
      completeLabel: 'Notice sent',
    );
  }
  return _richSurface(
    accent: const Color(0xff3e6b8f),
    icon: isPayment
        ? Icons.receipt_long_outlined
        : isDocument
        ? Icons.description_outlined
        : isApproval
        ? Icons.fact_check_outlined
        : Icons.folder_zip_outlined,
    title: id.contains('dues')
        ? 'Quarterly HOA dues'
        : id.contains('facility')
        ? 'Clubhouse Room A reservation'
        : id.contains('document')
        ? 'Community Rules document'
        : id.contains('architectural')
        ? 'Fence color request'
        : id.contains('committee')
        ? 'Architectural committee decision'
        : id.contains('notification')
        ? 'Owner decision notice'
        : 'HOA records export',
    subtitle: id.contains('dues')
        ? '450.00 USD due Jul 1, receipt to homeowner ledger.'
        : id.contains('facility')
        ? 'Room A, Saturday 2-5 PM, reservation fee attached.'
        : id.contains('document')
        ? 'Version 2026.3, members can open and acknowledge.'
        : id.contains('architectural')
        ? 'Lot 42 fence repaint, slate gray, decision due Friday.'
        : id.contains('committee')
        ? 'Board decision, conditions, comments, and owner follow-up.'
        : id.contains('notification')
        ? 'Approved with conditions, sent to owner inbox.'
        : 'Documents, receipts, facilities, and case history.',
    body: id.contains('dues') || id.contains('facility')
        ? 'Amount, owner, reservation or dues item, receipt destination, retry option, and status are visible.'
        : id.contains('document')
        ? 'Open the governing document with version, access state, acknowledgement, and download history.'
        : isApproval
        ? 'Request materials, committee note, approve/reject/request changes, and homeowner notification are visible.'
        : 'Prepare HOA records with documents, cases, receipts, redaction, checksum, and transfer progress.',
    facts: const [
      _RichFact(icon: Icons.home_outlined, label: 'Cedar Commons'),
      _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt/audit'),
      _RichFact(icon: Icons.description_outlined, label: 'Documents'),
      _RichFact(icon: Icons.event_available_outlined, label: 'Availability'),
      _RichFact(icon: Icons.task_alt_outlined, label: 'Outcome history'),
    ],
    actionPanelTitle: isApproval
        ? 'Committee decision'
        : isDocument
        ? 'Document access'
        : 'Reservation details',
    actionPanelBody: isApproval
        ? 'Approve, reject, request changes, comment, or reopen with a visible owner notification state.'
        : isDocument
        ? 'Open, download, acknowledge, request access, or view version history.'
        : 'Confirm the amount or scope, change details, retry if needed, and keep the receipt or export progress visible.',
    alternateActionLabel: isApproval
        ? 'Request changes'
        : isDocument
        ? 'Download PDF'
        : 'Change details',
    detailTitle: isApproval
        ? 'Request details'
        : isDocument
        ? 'Document details'
        : 'HOA details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.home_outlined,
        title: 'Property',
        body:
            'Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.description_outlined,
        title: 'Record',
        body:
            'Community Rules, Room A reservation, dues receipt, or architectural case.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.history_outlined,
        title: 'History',
        body:
            'Status, reviewer, receipt, version, timestamp, availability, and notification history remain visible.',
      ),
    ],
    stateTitle: 'Member result',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.inbox_outlined,
        title: 'Owner inbox',
        body:
            'Homeowner sees receipt, decision, document, reservation availability, sender, timestamp, and status.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.undo_outlined,
        title: 'Change option',
        body:
            'Cancel reservation, request changes, retry payment, or reopen where policy allows.',
      ),
    ],
    completeTitle: isApproval
        ? 'Request outcome saved'
        : isDocument
        ? 'Document viewed'
        : 'HOA record saved',
    completeBody: isDocument
        ? 'The document is viewed and acknowledged with access state, version history, and member download option visible.'
        : 'The homeowner record now shows owner, amount or decision, status history, and member next steps.',
    completeLabel: isApproval
        ? 'Outcome recorded'
        : isDocument
        ? 'Opened'
        : 'Saved',
  );
}

_RichWorkflowSpec _mosqueRichSpecFor(String id) {
  return _richSurface(
    accent: const Color(0xff2d6a4f),
    icon: id.contains('donation') || id.contains('donor')
        ? Icons.receipt_long_outlined
        : id.contains('care')
        ? Icons.volunteer_activism_outlined
        : Icons.search_outlined,
    title: id.contains('donor')
        ? 'Anonymous donor preference'
        : id.contains('donation')
        ? 'Sadaqah donation receipt'
        : id.contains('care')
        ? 'Private care request'
        : id.contains('notification')
        ? 'Neutral care receipt'
        : 'Iftar announcement answer',
    subtitle: id.contains('donation')
        ? '50.00 USD, anonymous option, receipt saved.'
        : id.contains('care')
        ? 'Meal support request with public summary and protected details.'
        : 'Member-safe update with respectful language and privacy boundaries.',
    body: id.contains('care')
        ? 'Submit or update care support without exposing sensitive details in notifications or public views.'
        : id.contains('donation') || id.contains('donor')
        ? 'Amount, donor visibility, receipt destination, and giving history are visible before saving.'
        : 'Search public announcement content with citations, sender, delivery timing, and member inbox preview.',
    facts: const [
      _RichFact(icon: Icons.favorite_outline, label: 'Community care'),
      _RichFact(icon: Icons.privacy_tip_outlined, label: 'Privacy checked'),
      _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt record'),
      _RichFact(icon: Icons.inbox_outlined, label: 'Member inbox'),
    ],
    actionPanelTitle: 'Save details',
    actionPanelBody:
        'Member-visible summary, protected details, receipt or citation, and recipient preview stay visible before sending.',
    alternateActionLabel: 'Update privacy',
    detailTitle: 'Masjid details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.message_outlined,
        title: 'Public summary',
        body:
            'Member-facing text stays neutral and does not reveal sensitive care details.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.lock_outline,
        title: 'Protected details',
        body:
            'Private notes are visible only to the care team or donor account owner.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.receipt_long_outlined,
        title: 'Record',
        body:
            'Donation receipt, care status, or citation evidence remains available.',
      ),
    ],
    stateTitle: 'Recipient result',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.mark_email_read_outlined,
        title: 'Member update',
        body:
            'Members see the safe notification, receipt, or cited answer in context.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.edit_note_outlined,
        title: 'Change option',
        body:
            'Update privacy, edit request, withdraw, or open receipt where allowed.',
      ),
    ],
    completeTitle: 'Masjid preference confirmed',
    completeBody:
        'Members see the privacy-safe update, receipt history or citation, confirmed status, current progress, and clear next step.',
    completeLabel: 'Saved',
  );
}

_RichWorkflowSpec _chessRichSpecFor(String id) {
  return _richSurface(
    layout: _RichWorkflowLayout.clubScoreboard,
    accent: const Color(0xff58432f),
    icon: Icons.grid_4x4_outlined,
    title: id.contains('match') ? 'Board 1 match result' : 'Chess Club home',
    subtitle: id.contains('match')
        ? 'Ava 1-0 Liam, Round 3 ladder match.'
        : 'Tonight ladder, pairings, standings, and next match.',
    body: id.contains('match')
        ? 'Record opponent, board, result, correction option, standings impact, and next pairing.'
        : 'Open a real club home with upcoming matches, active ladder, and member standings.',
    facts: const [
      _RichFact(icon: Icons.grid_4x4_outlined, label: 'Board 1'),
      _RichFact(icon: Icons.emoji_events_outlined, label: 'Round 3'),
      _RichFact(icon: Icons.group_outlined, label: '12 players'),
      _RichFact(icon: Icons.edit_note_outlined, label: 'Correction option'),
    ],
    actionPanelTitle: id.contains('match')
        ? 'Score details'
        : 'Club home details',
    actionPanelBody:
        'Confirm player names, round, board, result, edit option, and standings update before saving.',
    alternateActionLabel: 'Edit score',
    detailTitle: 'Match context',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Players',
        body: 'Ava vs Liam, Board 1, friendly ladder night.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.emoji_events_outlined,
        title: 'Result',
        body: 'Ava wins 1-0; standings and next pairing will update.',
      ),
    ],
    stateTitle: 'Club record',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.leaderboard_outlined,
        title: 'Standings',
        body: 'Players can see updated ladder position and next match.',
      ),
    ],
    completeTitle: 'Chess result saved',
    completeBody:
        'Chess Club shows board, players, result, correction option, standings impact, and next pairing.',
    completeLabel: 'Saved',
  );
}

_RichWorkflowSpec _cameraRichSpecFor(String id) {
  if (id.contains('photo-walk')) {
    return _richSurface(
      accent: const Color(0xff2f6f9f),
      icon: Icons.route_outlined,
      title: 'Downtown photo walk RSVP',
      subtitle: 'Sat 4:30 PM - Dock 4 to the riverfront pier.',
      body:
          'Choose Going, Maybe, or Not going after checking the route, host, meetup time, capacity, and gear reminder.',
      facts: const [
        _RichFact(icon: Icons.calendar_today_outlined, label: 'Sat, 4:30 PM'),
        _RichFact(icon: Icons.place_outlined, label: 'Dock 4 meetup'),
        _RichFact(icon: Icons.group_outlined, label: '12 going / 4 open'),
        _RichFact(icon: Icons.camera_alt_outlined, label: '35mm or phone'),
      ],
      actionSurfaceTitle: 'Photo walk RSVP',
      actionHeroSubtitle: 'Riverfront golden-hour route',
      actionHeroBody:
          'Confirm the walk route, host note, rain plan, attendee count, and reminder before saving your RSVP.',
      actionPanelTitle: 'Choose attendance',
      actionPanelBody:
          'Going reserves a spot; Maybe keeps the route in your inbox; Not going releases capacity for another member.',
      alternateActionLabel: 'Change response',
      detailTitle: 'Walk details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.route_outlined,
          title: 'Route',
          body: 'Dock 4, mural loop, riverfront pier, 75-minute walk.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Host',
          body: 'Avery Kim hosts and shares the rain-plan update.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.group_outlined,
          title: 'Capacity',
          body: '12 going, 4 spots open, waitlist opens at 16.',
        ),
      ],
      stateTitle: 'Response record',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.check_circle_outline,
          title: 'Going / maybe / not going',
          body: 'Response can be changed until Saturday noon.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.notifications_outlined,
          title: 'Reminder',
          body: 'Member inbox keeps route, gear note, and weather update.',
        ),
      ],
      completeTitle: 'Photo walk RSVP confirmed',
      completeBody:
          'Your photo walk attendance is confirmed with status, route, host, capacity, reminder, and change-response option visible.',
      receivedTitle: 'Photo walk update ready',
      receivedBody:
          'The member sees route, time, capacity, RSVP state, and reminder details.',
      completeLabel: 'RSVP saved',
    );
  }
  if (id.contains('critique')) {
    return _richSurface(
      accent: const Color(0xff6b5b95),
      icon: Icons.rate_review_outlined,
      title: 'Street portrait critique',
      subtitle: 'Evening Reflection - consent note and reviewer queue.',
      body:
          'Submit a photo for critique with title, prompt, visibility, reviewer, edit option, and comment result.',
      facts: const [
        _RichFact(icon: Icons.image_outlined, label: 'Evening Reflection'),
        _RichFact(icon: Icons.privacy_tip_outlined, label: 'Member visible'),
        _RichFact(icon: Icons.rate_review_outlined, label: 'Avery reviews'),
        _RichFact(icon: Icons.comment_outlined, label: 'Comments open'),
      ],
      actionSurfaceTitle: 'Critique submission',
      actionHeroSubtitle: 'Street portrait: Evening Reflection',
      actionHeroBody:
          'Confirm the image title, prompt, consent note, member visibility, and critique assignment before submitting.',
      actionPanelTitle: 'Critique details',
      actionPanelBody:
          'Submission enters Avery\'s queue; you can edit caption, replace image, or withdraw before comments.',
      alternateActionLabel: 'Edit critique',
      detailTitle: 'Submission details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.image_outlined,
          title: 'Image and title',
          body: 'Evening Reflection, street portrait, uploaded by Mina.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.question_answer_outlined,
          title: 'Prompt',
          body: 'Ask for feedback on composition, light, and crop.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.privacy_tip_outlined,
          title: 'Visibility',
          body: 'Visible to camera club members; consent note is attached.',
        ),
      ],
      stateTitle: 'Decision progress',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.rate_review_outlined,
          title: 'Reviewer queue',
          body: 'Avery receives the image, prompt, and visibility state.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.swap_horiz_outlined,
          title: 'Change option',
          body: 'Edit caption, replace image, withdraw, or resubmit.',
        ),
      ],
      completeTitle: 'Critique submitted',
      completeBody:
          'The critique shows image, prompt, consent, reviewer queue, edit option, and comment state.',
      receivedTitle: 'Critique result ready',
      receivedBody:
          'The member can read reviewer comments and follow up on the submitted image.',
      completeLabel: 'Submitted',
    );
  }
  return _richSurface(
    accent: const Color(0xff5a6f45),
    icon: Icons.camera_alt_outlined,
    title: '35mm prime lens loan',
    subtitle: 'Sam lends the lens Friday; return due Sunday evening.',
    body:
        'Request shared gear with owner, pickup time, borrower count, contact privacy, waitlist, and return state.',
    facts: const [
      _RichFact(icon: Icons.camera_outdoor_outlined, label: '35mm lens'),
      _RichFact(icon: Icons.person_outline, label: 'Owner: Sam'),
      _RichFact(icon: Icons.people_outline, label: '2 waiting'),
      _RichFact(icon: Icons.keyboard_return_outlined, label: 'Return Sunday'),
    ],
    actionSurfaceTitle: 'Gear loan request',
    actionHeroSubtitle: '35mm prime lens from Sam',
    actionHeroBody:
        'Confirm pickup, borrower queue, protected contact reveal, due date, and return option before requesting the loan.',
    actionPanelTitle: 'Gear request details',
    actionPanelBody:
        'Decision pending: the lender reviews borrower name, pickup window, contact preference, and cancel/return option.',
    alternateActionLabel: 'Cancel request',
    detailTitle: 'Loan details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.camera_outdoor_outlined,
        title: 'Item',
        body: '35mm prime lens, clean condition, filter included.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.schedule_outlined,
        title: 'Pickup and return',
        body: 'Pickup Friday 5 PM; return Sunday by 6 PM.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.privacy_tip_outlined,
        title: 'Contact',
        body: 'Phone is revealed only after owner approves the loan.',
      ),
    ],
    stateTitle: 'Borrower record',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.people_outline,
        title: 'Roster',
        body:
            'Borrower list, waitlist position, availability, and owner decision are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.keyboard_return_outlined,
        title: 'Return option',
        body: 'Mark returned, change pickup, or cancel request.',
      ),
    ],
    completeTitle: 'Gear loan requested',
    completeBody:
        'The loan request status shows item, owner, borrower queue, pickup, protected contact, and return option.',
    receivedTitle: 'Gear request ready',
    receivedBody:
        'The lender sees borrower, pickup, privacy, pending approval decision, and return plan.',
    completeLabel: 'Requested',
  );
}

_RichWorkflowSpec _platformRichSpecFor(String id) {
  if (id.contains('ad') || id.contains('banner') || id.contains('no-fill')) {
    final sensitive = id.contains('sensitive');
    final banner = id.contains('banner');
    return _richSurface(
      layout: _RichWorkflowLayout.adEntitlement,
      accent: sensitive
          ? const Color(0xff6b4f78)
          : banner
          ? const Color(0xff406d5a)
          : const Color(0xff7a5a2f),
      icon: sensitive
          ? Icons.shield_outlined
          : banner
          ? Icons.web_asset_off_outlined
          : Icons.campaign_outlined,
      title: sensitive
          ? 'Sensitive page ad guard'
          : banner
          ? 'Top banner no-fill'
          : 'Sponsored stream message',
      subtitle: sensitive
          ? 'Protected context blocks ad delivery and click tracking.'
          : banner
          ? 'Reserved banner space stays stable without sponsor fill.'
          : 'Sponsor disclosure, placement, impression, and member context.',
      body: sensitive
          ? 'Show the member why ads are suppressed, preserve layout, and avoid leaking protected context.'
          : banner
          ? 'Show a clear no-sponsored-message state with reserved space, disclosure, and no overlap.'
          : 'Show sponsor, disclosure, message copy, impression state, and dismiss/report alternatives.',
      facts: [
        if (!sensitive)
          const _RichFact(icon: Icons.campaign_outlined, label: 'Disclosure'),
        if (banner)
          const _RichFact(
            icon: Icons.web_asset_outlined,
            label: 'Slot reserved',
          ),
        if (sensitive)
          const _RichFact(icon: Icons.shield_outlined, label: 'Protected page'),
        const _RichFact(icon: Icons.visibility_outlined, label: 'No overlap'),
        const _RichFact(icon: Icons.analytics_outlined, label: 'Audit state'),
        const _RichFact(icon: Icons.block_outlined, label: 'Dismiss/report'),
      ],
      actionSurfaceTitle: sensitive
          ? 'Sensitive ad decision'
          : banner
          ? 'Top banner slot'
          : 'Sponsored message details',
      actionHeroSubtitle: sensitive
          ? 'Protected care context'
          : banner
          ? 'No sponsor available right now'
          : 'Local sponsor: community newsletter',
      actionHeroBody: sensitive
          ? 'The page records a no-fill reason without revealing protected member context or enabling click tracking.'
          : banner
          ? 'Reserved space remains stable and tells members why no sponsored message is displayed.'
          : 'Confirm the sponsor label, disclosure, placement, content, impression, and report option.',
      actionPanelTitle: sensitive
          ? 'Protected no-fill ready'
          : banner
          ? 'No-fill state ready'
          : 'Sponsored message ready',
      actionPanelBody: sensitive
          ? 'Ad delivery is suppressed, no click is recorded, and the member sees a privacy-safe reason.'
          : banner
          ? 'The banner stays reserved, avoids content jump, and records the no-fill reason.'
          : 'The member can dismiss, report, or continue; impression is recorded only for filled ads.',
      alternateActionLabel: sensitive
          ? 'Policy details'
          : banner
          ? 'Refresh slot'
          : 'Report sponsor',
      detailTitle: sensitive
          ? 'Privacy guard details'
          : banner
          ? 'Banner slot details'
          : 'Sponsored message details',
      detailRows: [
        _ActionSurfaceDetail(
          icon: sensitive
              ? Icons.shield_outlined
              : banner
              ? Icons.web_asset_outlined
              : Icons.storefront_outlined,
          title: sensitive
              ? 'Sensitive context'
              : banner
              ? 'Reserved placement'
              : 'Sponsor',
          body: sensitive
              ? 'Care/protected content suppresses ad targeting and click tracking.'
              : banner
              ? 'Top banner slot remains visible with no sponsored message right now.'
              : 'Disclosure: Sponsored by Neighborhood Newsletter.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.info_outline,
          title: 'Reason',
          body: sensitive
              ? 'No fill: sensitive context.'
              : banner
              ? 'No fill: no eligible sponsor for this community moment.'
              : 'Filled ad: eligible community stream placement.',
        ),
        const _ActionSurfaceDetail(
          icon: Icons.report_outlined,
          title: 'Member control',
          body:
              'Dismiss, report, or continue without losing place in the stream.',
        ),
      ],
      stateTitle: 'Ad delivery record',
      stateRows: [
        _ActionSurfaceDetail(
          icon: Icons.analytics_outlined,
          title: sensitive || banner ? 'No impression' : 'Impression recorded',
          body: sensitive || banner
              ? 'No impression/click is recorded because the slot is not filled.'
              : 'Impression is recorded with sponsor disclosure and audit trail.',
        ),
        const _ActionSurfaceDetail(
          icon: Icons.visibility_outlined,
          title: 'Layout',
          body: 'Reserved space prevents overlap, crowding, and content jumps.',
        ),
      ],
      completeTitle: sensitive
          ? 'Sensitive no-fill recorded'
          : banner
          ? 'Banner no-fill recorded'
          : 'Sponsored message details',
      completeBody: sensitive
          ? 'Protected context, no-fill reason, layout preservation, and no-click state remain visible.'
          : banner
          ? 'No sponsored message is shown, reserved space remains stable, and no-fill reason is recorded.'
          : 'Sponsor, disclosure, impression, report option, and stream placement remain visible.',
      receivedTitle: 'Ad state ready',
      receivedBody:
          'The member can see disclosure/no-fill reason, reserved layout, and any available control.',
      completeLabel: sensitive || banner ? 'No fill' : 'Reviewed',
    );
  }
  if (id.contains('message')) {
    return _richSurface(
      layout: _RichWorkflowLayout.messageThread,
      accent: const Color(0xff315c8a),
      icon: Icons.chat_bubble_outline,
      title: 'Community message thread',
      subtitle: 'Maya Chen to Jordan Lee - unread member thread.',
      body:
          'Read sender, recipient, timestamp, message preview, unread receipt, reply option, mute, and archive controls.',
      facts: const [
        _RichFact(icon: Icons.person_outline, label: 'Maya -> Jordan'),
        _RichFact(icon: Icons.mark_email_unread_outlined, label: 'Unread'),
        _RichFact(icon: Icons.reply_outlined, label: 'Reply available'),
        _RichFact(icon: Icons.archive_outlined, label: 'Archive option'),
      ],
      actionSurfaceTitle: 'Message thread',
      actionHeroSubtitle: 'Community message from Maya',
      actionHeroBody:
          'Open the thread, confirm sender and body, reply, mute, archive, or block if needed.',
      actionPanelTitle: 'Reply details',
      actionPanelBody:
          'Reply keeps the thread member-scoped and preserves read/unread receipt.',
      alternateActionLabel: 'Archive thread',
      detailTitle: 'Thread details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Sender and recipient',
          body: 'Maya Chen -> Jordan Lee, members of the same community.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.message_outlined,
          title: 'Message body',
          body: 'Can you bring the sign-in sheets before the meetup?',
        ),
        _ActionSurfaceDetail(
          icon: Icons.schedule_outlined,
          title: 'Timestamp',
          body: 'Today 9:12 AM, unread until opened.',
        ),
      ],
      stateTitle: 'Conversation record',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.reply_outlined,
          title: 'Actions',
          body: 'Reply, mute, archive, or block remain available.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.mark_email_read_outlined,
          title: 'Recipient result',
          body: 'Thread updates to read with reply history after action.',
        ),
      ],
      completeTitle: 'Message sent',
      completeBody:
          'The thread shows the sent message, receiver read status, timestamp, reply option, receipt history, and archive/block controls.',
      receivedTitle: 'Message received',
      receivedBody:
          'The receiver sees sender, message body, timestamp, unread/read receipt, and reply action.',
      completeLabel: 'Thread updated',
    );
  }
  if (id.contains('blocked')) {
    return _richSurface(
      layout: _RichWorkflowLayout.messageThread,
      accent: const Color(0xff7a4e4e),
      icon: Icons.block_outlined,
      title: 'Blocked connection guard',
      subtitle: 'Maya cannot send an invite to blocked member Jordan.',
      body:
          'Show sender, protected recipient, attempted invite body, disabled send option, safety reason, appeal/unblock option, and audit timestamp.',
      facts: const [
        _RichFact(icon: Icons.block_outlined, label: 'Blocked'),
        _RichFact(icon: Icons.person_outline, label: 'Maya -> Jordan'),
        _RichFact(icon: Icons.message_outlined, label: 'Invite blocked'),
        _RichFact(icon: Icons.security_outlined, label: 'Safety audit'),
      ],
      actionSurfaceTitle: 'Connection safety guard',
      actionHeroSubtitle: 'Invite body blocked before delivery',
      actionHeroBody:
          'Confirm sender Maya, protected recipient Jordan, attempted invite text, block reason, disabled delivery, and unblock/appeal option.',
      actionPanelTitle: 'Safety details',
      actionPanelBody:
          'The member cannot send the invite while the block is active; the attempted message body stays in audit, not in Jordan\'s inbox.',
      alternateActionLabel: 'Open block details',
      detailTitle: 'Safety details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Sender and protected recipient',
          body:
              'Maya Chen attempted to invite Jordan Lee; Jordan remains protected by an active block.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.message_outlined,
          title: 'Attempted invite body',
          body:
              'Invite text: "Join my community circle for Saturday event planning."',
        ),
        _ActionSurfaceDetail(
          icon: Icons.article_outlined,
          title: 'Community safety record',
          body: 'Safety note from moderator Alex, updated today at 10:30 AM.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.block_outlined,
          title: 'Disabled action',
          body:
              'Send invite is disabled; unblock or appeal is required before contact.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.history_outlined,
          title: 'Audit',
          body:
              'Audit records sender, blocked target, attempted body, timestamp, and moderator action.',
        ),
      ],
      stateTitle: 'Decision recorded',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.security_outlined,
          title: 'Receiver protection',
          body: 'The protected member does not receive unsafe contact.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.undo_outlined,
          title: 'Continuation',
          body: 'Moderator can unblock or keep the guard active.',
        ),
      ],
      completeTitle: 'Blocked state confirmed',
      completeBody:
          'The community safety record shows sender, protected recipient, attempted body, disabled action, audit timestamp, and appeal/unblock option.',
      receivedTitle: 'Prevention received',
      receivedBody:
          'The member sees a safe explanation, no unsafe invite is delivered, and unblock/appeal option remains visible.',
      completeLabel: 'Blocked',
    );
  }
  final isConnectionsEntry = id.contains('connections-entry');
  return _richSurface(
    layout: _RichWorkflowLayout.messageThread,
    accent: const Color(0xff315c8a),
    icon: isConnectionsEntry
        ? Icons.people_alt_outlined
        : Icons.person_add_alt_outlined,
    title: isConnectionsEntry
        ? 'Connections inbox'
        : 'Member connection invite',
    subtitle: isConnectionsEntry
        ? 'Pending invite from Maya, accepted contacts, and blocked-state summary.'
        : 'Maya invites Jordan with accept/decline, cancel, and block options.',
    body: isConnectionsEntry
        ? 'Manage connection requests with sender, message body, timestamp, mutual community, accept/decline choices, and blocked-contact status.'
        : 'Send a connection invite with sender, recipient, invite message body, timestamp, accept/decline option, and inbox state.',
    facts: const [
      _RichFact(icon: Icons.person_outline, label: 'Maya -> Jordan'),
      _RichFact(icon: Icons.message_outlined, label: 'Invite message'),
      _RichFact(icon: Icons.check_circle_outline, label: 'Accept/decline'),
      _RichFact(icon: Icons.schedule_outlined, label: 'Today 9:12 AM'),
    ],
    actionSurfaceTitle: isConnectionsEntry
        ? 'Connections inbox'
        : 'Connection invite',
    actionHeroSubtitle: isConnectionsEntry
        ? 'Pending and active community connections'
        : 'Invite Jordan to connect',
    actionHeroBody: isConnectionsEntry
        ? 'Open sender, invite body, timestamp, accept/decline buttons, active contacts, and blocked state.'
        : 'Confirm recipient Jordan, sender Maya, invite body, timestamp, and the recipient inbox preview before sending.',
    actionPanelTitle: 'Invite details',
    actionPanelBody:
        'Recipient sees the invite text, sender, timestamp, mutual community, accept, decline, block, and thread-continuation options.',
    alternateActionLabel: 'Cancel invite',
    detailTitle: 'Invite details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Sender and recipient',
        body: 'Maya Chen invites Jordan Lee to connect inside the community.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.message_outlined,
        title: 'Invite body',
        body:
            'Message: "Want to coordinate the Saturday welcome table together?"',
      ),
      _ActionSurfaceDetail(
        icon: Icons.schedule_outlined,
        title: 'Timestamp',
        body: 'Today 9:12 AM, expires in 7 days if unanswered.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.person_add_alt_outlined,
        title: 'Invite record',
        body: 'Pending invite can be accepted, declined, canceled, or blocked.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.inbox_outlined,
        title: 'Receiver inbox',
        body: 'Recipient inbox shows sender, context, and decision buttons.',
      ),
    ],
    stateTitle: 'Relationship record',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.check_circle_outline,
        title: 'Accepted',
        body: 'Accepted invites open a thread and connection history.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.close_outlined,
        title: 'Declined or canceled',
        body: 'Decline/cancel keeps history without opening a thread.',
      ),
    ],
    completeTitle: 'Connection invite sent',
    completeBody:
        'The invite shows sender, recipient, message body, timestamp, accept/decline state, cancel option, and inbox continuation.',
    receivedTitle: 'Connection invite ready',
    receivedBody:
        'The receiver sees sender, invite body, timestamp, mutual community, and can accept, decline, block, or open the related thread.',
    completeLabel: 'Invite sent',
  );
}

_RichWorkflowSpec _adOffRichSpecFor(String id) {
  final receipt = id.contains('receipt');
  final suppression = id.contains('suppression');
  final settlement = id.contains('settlement');
  final entitlement = id.contains('entitlement');
  final community = id.contains('community');
  if (receipt) {
    return _richSurface(
      accent: const Color(0xff5b5f97),
      icon: Icons.receipt_long_outlined,
      title: 'Ad-off receipt history',
      subtitle: 'Receipt ADO-1042 - 4.99 USD monthly member plan.',
      body:
          'Open receipt evidence with payer, amount, date, entitlement scope, payment state, refund option, and exportable audit record.',
      facts: const [
        _RichFact(icon: Icons.receipt_long_outlined, label: 'ADO-1042'),
        _RichFact(icon: Icons.payments_outlined, label: '4.99 USD'),
        _RichFact(icon: Icons.person_outline, label: 'Member payer'),
        _RichFact(icon: Icons.download_outlined, label: 'Export receipt'),
      ],
      actionSurfaceTitle: 'Receipt evidence',
      actionHeroSubtitle: 'Member ad-off receipt',
      actionHeroBody:
          'Amount, payer, scope, payment progress, refund/retry option, and audit metadata are visible before sharing or exporting.',
      actionPanelTitle: 'Receipt details',
      actionPanelBody:
          'Receipt record, history, support, export, refund questions, and entitlement restore stay visible.',
      alternateActionLabel: 'Export receipt',
      detailTitle: 'Receipt details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt',
          body: 'ADO-1042, paid today at 2:10 PM, card ending 4242.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.workspace_premium_outlined,
          title: 'Entitlement',
          body: 'Member ad-free entitlement active through Aug 30.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          body: 'Refund/retry/support history is linked to this receipt.',
        ),
      ],
      stateTitle: 'Receipt record',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.download_outlined,
          title: 'Export',
          body: 'Receipt can be exported with checksum and audit trail.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.restore_outlined,
          title: 'Restore',
          body: 'Restore purchase uses this receipt and payer context.',
        ),
      ],
      completeTitle: 'Receipt opened',
      completeBody:
          'Receipt status is confirmed with amount, payer, scope, entitlement, export option, and support history.',
      receivedTitle: 'Receipt ready',
      receivedBody:
          'The member can open receipt history, entitlement record, and export support evidence.',
      completeLabel: 'Receipt',
    );
  }
  if (suppression) {
    return _richSurface(
      accent: const Color(0xff4f6f5b),
      icon: Icons.visibility_off_outlined,
      title: 'Ad suppression proof',
      subtitle: 'Sponsored slots suppressed by active ad-off entitlement.',
      body:
          'Verify the 4.99 USD monthly ad-free plan, which ad slots are suppressed, why no ad rendered, what entitlement applies, and how to restore or audit the decision.',
      facts: const [
        _RichFact(icon: Icons.visibility_off_outlined, label: 'Ads hidden'),
        _RichFact(icon: Icons.verified_user_outlined, label: 'Entitled'),
        _RichFact(icon: Icons.campaign_outlined, label: '2 slots checked'),
        _RichFact(icon: Icons.history_outlined, label: 'Audit trail'),
      ],
      actionSurfaceTitle: 'Suppression decision',
      actionHeroSubtitle: 'No sponsored message due to ad-off',
      actionHeroBody:
          'Confirm the 4.99 USD entitlement, slot list, no-fill reason, restoration option, and settlement utility audit.',
      actionPanelTitle: 'Suppression proof',
      actionPanelBody:
          'Confirm ad suppression status, 4.99 USD plan amount, each eligible slot, no impression, and the entitlement that caused it.',
      alternateActionLabel: 'Restore ads',
      detailTitle: 'Suppressed slots',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.web_asset_outlined,
          title: 'Top banner',
          body:
              'Suppressed: member ad-off entitlement active on the 4.99 USD monthly plan.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.dynamic_feed_outlined,
          title: 'In-stream placement',
          body: 'Suppressed: no impression or click recorded.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.restore_outlined,
          title: 'Restore option',
          body: 'Member can restore ads or manage subscription.',
        ),
      ],
      stateTitle: 'After suppression',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.analytics_outlined,
          title: 'No impression',
          body: 'Analytics records suppression, not an ad impression.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Evidence',
          body: 'Receipt and entitlement link explain the suppression.',
        ),
      ],
      completeTitle: 'Suppression verified',
      completeBody:
          'Ad suppression status is confirmed with suppressed slots, entitlement, no-impression history, restore option, and audit evidence.',
      receivedTitle: 'Ad-free state ready',
      receivedBody:
          'The member sees suppression history, which slots were hidden, and how to manage or restore ads.',
      completeLabel: 'Suppressed',
    );
  }
  if (settlement) {
    return _richSurface(
      accent: const Color(0xff6a6d3f),
      icon: Icons.account_balance_outlined,
      title: 'Ad-off settlement allocation',
      subtitle: 'Community utility allocation from ad-off revenue.',
      body:
          'Confirm monthly revenue, platform fee, community utility allocation, settlement status, and audit/rollback option.',
      facts: const [
        _RichFact(icon: Icons.payments_outlined, label: '120.00 USD'),
        _RichFact(icon: Icons.account_balance_outlined, label: 'Utility fund'),
        _RichFact(icon: Icons.schedule_outlined, label: 'Month end'),
        _RichFact(icon: Icons.verified_outlined, label: 'Audit ready'),
      ],
      actionSurfaceTitle: 'Settlement utility',
      actionHeroSubtitle: 'June ad-off utility allocation',
      actionHeroBody:
          'Confirm allocation, settlement destination, audit trail, and correction option before marking utility ready.',
      actionPanelTitle: 'Settlement details',
      actionPanelBody:
          'Admins see amount, destination, settlement status, receipt linkage, and rollback/correction option.',
      alternateActionLabel: 'Open allocation',
      detailTitle: 'Settlement details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.account_balance_outlined,
          title: 'Destination',
          body: 'Community utility fund receives June ad-off allocation.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.payments_outlined,
          title: 'Amount',
          body: '120.00 USD community plan, 96.00 USD utility allocation.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.history_outlined,
          title: 'Audit',
          body: 'Receipt, entitlement, and settlement run are linked.',
        ),
      ],
      stateTitle: 'Settlement state',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.verified_outlined,
          title: 'Ready',
          body: 'Settlement is ready for owner action and export.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.undo_outlined,
          title: 'Correction option',
          body: 'Admin can correct allocation before final settlement.',
        ),
      ],
      completeTitle: 'Settlement recorded',
      completeBody:
          'The settlement surface shows amount, destination, audit, correction option, and utility status.',
      receivedTitle: 'Settlement state ready',
      receivedBody:
          'Admins can open amount, destination, audit trail, and correction option.',
      completeLabel: 'Reviewed',
    );
  }
  if (entitlement) {
    return _richSurface(
      accent: const Color(0xff4d668f),
      icon: Icons.verified_user_outlined,
      title: 'Ad-off entitlement record',
      subtitle: 'Active member entitlement through Aug 30.',
      body:
          'Open entitlement scope, 4.99 USD monthly amount, expiration, subscription state, restore option, receipt link, and ad-free member view.',
      facts: const [
        _RichFact(icon: Icons.verified_user_outlined, label: 'Active'),
        _RichFact(icon: Icons.calendar_today_outlined, label: 'Aug 30'),
        _RichFact(icon: Icons.restore_outlined, label: 'Restore option'),
        _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt linked'),
      ],
      actionSurfaceTitle: 'Entitlement record',
      actionHeroSubtitle: 'Member ad-free entitlement',
      actionHeroBody:
          'Confirm scope, 4.99 USD renewal amount, expiration, restore, receipt, and ad-slot member view.',
      actionPanelTitle: 'Entitlement details',
      actionPanelBody:
          'Confirm subscription record, 4.99 USD plan amount, manage subscription, restore purchase, open receipt, or verify suppressed ad slots.',
      alternateActionLabel: 'Manage plan',
      detailTitle: 'Entitlement details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Scope',
          body:
              'Member-level ad-off for current account and communities at 4.99 USD monthly.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.calendar_today_outlined,
          title: 'Expiration',
          body: 'Active through Aug 30, renews monthly.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt',
          body: 'Receipt ADO-1042 proves payer and entitlement state.',
        ),
      ],
      stateTitle: 'Member result',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.visibility_off_outlined,
          title: 'Ad-free slots',
          body: 'Eligible sponsored slots are suppressed while active.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.restore_outlined,
          title: 'Restore',
          body: 'Restore purchase and manage plan remain available.',
        ),
      ],
      completeTitle: 'Entitlement checked',
      completeBody:
          'Subscription status is confirmed with entitlement scope, expiration, receipt, restore option, and ad-free slot history.',
      receivedTitle: 'Entitlement ready',
      receivedBody:
          'The member can verify active ad-off subscription, receipt history, and suppressed ad status.',
      completeLabel: 'Active',
    );
  }
  return _richSurface(
    accent: const Color(0xff5b5f97),
    icon: Icons.workspace_premium_outlined,
    title: community ? 'Community ad-off checkout' : 'Member ad-off checkout',
    subtitle: community
        ? '120.00 USD monthly community ad-free plan.'
        : '4.99 USD monthly member ad-free plan.',
    body:
        'Confirm payer, amount, entitlement scope, payment method, renewal, receipt, and restore/manage option before checkout.',
    facts: [
      _RichFact(
        icon: Icons.credit_card_outlined,
        label: community ? '120.00 USD' : '4.99 USD',
      ),
      _RichFact(
        icon: Icons.person_outline,
        label: community ? 'Community pays' : 'Member pays',
      ),
      const _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt'),
      const _RichFact(icon: Icons.visibility_off_outlined, label: 'Ads hidden'),
    ],
    actionSurfaceTitle: community
        ? 'Community ad-off checkout'
        : 'Member ad-off checkout',
    actionHeroSubtitle: community
        ? 'Ad-free for all eligible community members'
        : 'Ad-free for this member account',
    actionHeroBody: community
        ? 'Confirm payer, amount, renewal, utility settlement, receipt, and receiver entitlement before checkout.'
        : 'Confirm payer, amount, renewal, receipt, restore option, and suppressed ad slots before checkout.',
    actionPanelTitle: 'Payment summary',
    actionPanelBody:
        'Confirm checkout status; purchase creates receipt evidence, activates entitlement, and leaves manage/cancel/restore actions available.',
    alternateActionLabel: 'Change plan',
    detailTitle: 'Checkout details',
    detailRows: [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Payer and scope',
        body: community
            ? 'Community admin pays 120.00 USD/month for eligible members.'
            : 'Member pays 4.99 USD/month for their account.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.credit_card_outlined,
        title: 'Payment',
        body: community
            ? 'Payment method, renewal, utility allocation, and fee details are shown.'
            : 'Payment method, renewal, receipt, retry, and cancellation are shown.',
      ),
      const _ActionSurfaceDetail(
        icon: Icons.visibility_off_outlined,
        title: 'Ad-free result',
        body: 'Eligible sponsored slots become suppressed after payment.',
      ),
    ],
    stateTitle: 'Checkout result',
    stateRows: [
      _ActionSurfaceDetail(
        icon: Icons.verified_outlined,
        title: 'Entitlement',
        body: community
            ? 'Community entitlement activates for eligible members.'
            : 'Member entitlement activates immediately.',
      ),
      const _ActionSurfaceDetail(
        icon: Icons.restore_outlined,
        title: 'Manage',
        body: 'Manage subscription, cancel, restore, retry, or open receipt.',
      ),
    ],
    completeTitle: community
        ? 'Community ad-off purchased'
        : 'Member ad-off purchased',
    completeBody:
        'Checkout status is complete with payer, amount, scope, receipt, entitlement, manage option, and suppressed ad result.',
    receivedTitle: 'Ad-off entitlement ready',
    receivedBody:
        'The receiver sees entitlement record, receipt history, suppressed ad slots, and manage/restore next step.',
    completeLabel: 'Purchased',
  );
}

_RichWorkflowSpec _exportRichSpecFor(String id) {
  final isImport =
      id.contains('import-preview') || id.contains('import-replay');
  final isTransfer = id.contains('transfer-verification');
  final isRedaction = id.contains('protected-redaction');
  final isRollback = id.contains('transfer-rollback');
  final isSchema = id.contains('schema-listing');
  final isChecksum = id.contains('checksum');
  final title = isImport
      ? 'Legacy import preview'
      : isRedaction
      ? 'Protected redaction preview'
      : isSchema
      ? 'Exportable schema catalog'
      : isChecksum
      ? 'Checksum evidence record'
      : isRollback
      ? 'Provider rollback plan'
      : isTransfer
      ? 'Provider transfer verification'
      : 'Full export bundle';
  final subtitle = isImport
      ? 'Preview rows, conflicts, replay checkpoint, and rollback marker.'
      : isRedaction
      ? 'Mask protected fields with policy reasons before export.'
      : isSchema
      ? 'List schemas, field classes, custom records, and history.'
      : isChecksum
      ? 'Verify digest, file count, byte size, and integrity receipt.'
      : isRollback
      ? 'Recover from provider mismatch using the last good snapshot.'
      : isTransfer
      ? 'Verify destination provider, handshake, receipt, and audit trail.'
      : 'Generate a downloadable package with scope, redaction, and checksum.';
  final body = isImport
      ? 'Open imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing.'
      : isRedaction
      ? 'Open protected youth roster fields, guardian-visible profile details, coach-only notes, masked phone, care, vault, and payment fields with policy reasons and reveal permissions.'
      : isSchema
      ? 'Open every exportable table, field classification, custom schema, version history, and include/exclude decision.'
      : isChecksum
      ? 'Compare source checksum, package checksum, byte size, and integrity receipt before marking the export verified.'
      : isRollback
      ? 'Choose retry, cancel, or rollback after a destination mismatch and keep the recovery audit visible.'
      : isTransfer
      ? 'Confirm source hash, destination hash, provider ID, transfer timestamp, and receipt before closing transfer.'
      : 'Generate the full export bundle with selected records, redaction preview, checksum, download state, and audit trail.';
  final actionPanelTitle = isImport
      ? 'Import replay checkpoint'
      : isRedaction
      ? 'Redaction policy checkpoint'
      : isSchema
      ? 'Schema scope checkpoint'
      : isChecksum
      ? 'Checksum verification checkpoint'
      : isRollback
      ? 'Transfer rollback checkpoint'
      : isTransfer
      ? 'Transfer verification checkpoint'
      : 'Export bundle checkpoint';
  final actionPanelBody = isImport
      ? 'Resolve duplicate rows, confirm checkpoint I-118, then replay the import with retry and rollback available.'
      : isRedaction
      ? 'Apply the protected-field mask and keep before/after preview, policy reason, and reveal permission visible.'
      : isSchema
      ? 'Confirm which schemas are included and whether custom records need version history.'
      : isChecksum
      ? 'Run verification, compare digests, and store the integrity receipt with export scope.'
      : isRollback
      ? 'Restore the last good snapshot or retry destination transfer after reviewing mismatch details.'
      : isTransfer
      ? 'Compare destination provider receipt with source package hash before confirming transfer.'
      : 'Generate the package after confirming scope, redaction preview, destination, and audit history.';
  final alternateLabel = isImport
      ? 'Skip duplicate'
      : isRedaction
      ? 'Reveal field'
      : isSchema
      ? 'Exclude schema'
      : isChecksum
      ? 'Verify again'
      : isRollback
      ? 'Retry transfer'
      : isTransfer
      ? 'Hold transfer'
      : 'Change scope';
  final detailRows = isImport
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.preview_outlined,
            title: 'Rows preview',
            body:
                '48 members, 22 documents, 12 receipts, and three duplicate records are visible.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.warning_amber_outlined,
            title: 'Conflict choices',
            body:
                'Duplicates can be accepted, skipped, or held for owner decision.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Replay checkpoint',
            body:
                'Checkpoint I-118 lets the owner retry or roll back the import.',
          ),
        ]
      : isRedaction
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Protected values',
            body:
                'Protected youth profile, minor roster phone, care, vault, payment, and private notes are masked.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.rule_outlined,
            title: 'Policy reason',
            body:
                'Each masked field shows guardian or coach visibility policy and the actor identity allowed to reveal it.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.preview_outlined,
            title: 'Before/after',
            body:
                'Owner compares source label, exported safe value, and redaction count.',
          ),
        ]
      : isSchema
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.schema_outlined,
            title: 'Schema list',
            body:
                'community, member, receipt, document, message, task, event, and custom tables.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.key_outlined,
            title: 'Field classes',
            body:
                'Public, member, protected, payment, audit, and custom field classes are shown.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Version history',
            body:
                'Each schema row includes version, owner, and last export progress.',
          ),
        ]
      : isChecksum
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Digest',
            body:
                'Checksum 9A7F-PORT, file count 84, size 18.4 MB, SHA-256 verified.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.compare_arrows_outlined,
            title: 'Comparison',
            body:
                'Source package hash and destination package hash must match.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.receipt_long_outlined,
            title: 'Integrity receipt',
            body:
                'Receipt links checksum, scope, timestamp, and verifier identity.',
          ),
        ]
      : isRollback
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.error_outline,
            title: 'Mismatch',
            body:
                'Destination provider hash differs from source package checksum.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Rollback checkpoint',
            body: 'Snapshot E-204 is the last good state and can be restored.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Recovery audit',
            body:
                'Audit logs who started rollback, time, scope, and restored status.',
          ),
        ]
      : isTransfer
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.cloud_sync_outlined,
            title: 'Destination',
            body: 'Provider Cloud HOA receives bundle E-204 after handshake.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Hash match',
            body:
                'Source hash and provider receipt hash match before closeout.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.receipt_long_outlined,
            title: 'Receipt',
            body: 'Transfer receipt shows provider ID, timestamp, and status.',
          ),
        ]
      : const [
          _ActionSurfaceDetail(
            icon: Icons.folder_zip_outlined,
            title: 'Bundle contents',
            body:
                'Members, receipts, documents, messages, custom records, and export metadata.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Redaction',
            body: 'Protected fields are counted and masked before download.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.file_download_outlined,
            title: 'Download',
            body:
                'Owner sees file size, checksum, download progress, and next transfer step.',
          ),
        ];
  final stateRows = isImport
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.playlist_add_check_outlined,
            title: 'Import state',
            body:
                'Replay status, duplicate decisions, and rollback marker remain visible.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Undo option',
            body: 'Owner can stop replay or roll back to checkpoint I-118.',
          ),
        ]
      : isRollback
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.restore_outlined,
            title: 'Restored state',
            body:
                'Records return to snapshot E-204 and destination status is marked rolled back.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.refresh_outlined,
            title: 'Retry option',
            body:
                'Owner can retry transfer after provider mismatch is resolved.',
          ),
        ]
      : const [
          _ActionSurfaceDetail(
            icon: Icons.file_download_outlined,
            title: 'Owner artifact',
            body:
                'Owner can download or transfer only after required verification succeeds.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Audit trail',
            body:
                'Scope, decision, timestamp, checksum, and actor are preserved.',
          ),
        ];
  return _richSurface(
    layout: _RichWorkflowLayout.exportWizard,
    accent: const Color(0xff536878),
    icon: isImport
        ? Icons.preview_outlined
        : isRedaction
        ? Icons.visibility_off_outlined
        : isSchema
        ? Icons.schema_outlined
        : isChecksum
        ? Icons.verified_outlined
        : isRollback
        ? Icons.undo_outlined
        : isTransfer
        ? Icons.cloud_sync_outlined
        : Icons.folder_zip_outlined,
    title: title,
    subtitle: subtitle,
    body: body,
    facts: [
      _RichFact(
        icon: isSchema ? Icons.schema_outlined : Icons.dataset_outlined,
        label: isSchema ? '8 schemas listed' : 'Scope selected',
      ),
      _RichFact(
        icon: isRedaction
            ? Icons.visibility_off_outlined
            : isImport
            ? Icons.warning_amber_outlined
            : Icons.verified_outlined,
        label: isRedaction
            ? 'Policy masks'
            : isImport
            ? '3 conflicts'
            : 'Verified',
      ),
      _RichFact(
        icon: isRollback ? Icons.restore_outlined : Icons.receipt_long_outlined,
        label: isRollback ? 'Checkpoint E-204' : 'Audit receipt',
      ),
      _RichFact(
        icon: isTransfer
            ? Icons.cloud_done_outlined
            : Icons.file_download_outlined,
        label: isTransfer ? 'Provider receipt' : 'Owner artifact',
      ),
    ],
    actionPanelTitle: actionPanelTitle,
    actionPanelBody: actionPanelBody,
    alternateActionLabel: alternateLabel,
    detailTitle: isSchema
        ? 'Schema details'
        : isImport
        ? 'Import details'
        : isRollback
        ? 'Recovery details'
        : isTransfer
        ? 'Transfer details'
        : 'Package details',
    detailRows: detailRows,
    stateTitle: isRollback
        ? 'Recovery state'
        : isImport
        ? 'Replay state'
        : 'Verification state',
    stateRows: stateRows,
    completeTitle: isImport
        ? 'Import replay ready'
        : isRedaction
        ? 'Redaction applied'
        : isSchema
        ? 'Schema scope saved'
        : isChecksum
        ? 'Checksum verified'
        : isRollback
        ? 'Rollback planned'
        : isTransfer
        ? 'Transfer verified'
        : 'Export bundle generated',
    completeBody: isImport
        ? 'Import preview shows row counts, duplicate decisions, checkpoint, retry, and rollback state.'
        : isRedaction
        ? 'Protected redaction shows youth profile and roster details, guardian or coach visibility, masked fields, policy reasons, before/after preview, and audit evidence.'
        : isSchema
        ? 'Schema catalog shows exportable tables, field classes, history, and include/exclude scope.'
        : isChecksum
        ? 'Checksum evidence shows digest, file count, byte size, verification status, and integrity receipt.'
        : isRollback
        ? 'Rollback plan shows mismatch reason, checkpoint, restore action, retry option, and recovery audit.'
        : isTransfer
        ? 'Transfer verification shows provider, hash match, receipt, timestamp, and closeout state.'
        : 'Full export bundle shows contents, redaction, checksum, file size, download progress, and audit trail.',
    completeLabel: isRollback
        ? 'Rollback ready'
        : isTransfer
        ? 'Verified'
        : isChecksum
        ? 'Verified'
        : isImport
        ? 'Previewed'
        : 'Ready',
  );
}

_RichWorkflowSpec _richSurface({
  _RichWorkflowLayout? layout,
  required Color accent,
  required IconData icon,
  required String title,
  required String subtitle,
  required String body,
  required List<_RichFact> facts,
  required String detailTitle,
  required List<_ActionSurfaceDetail> detailRows,
  required String stateTitle,
  required List<_ActionSurfaceDetail> stateRows,
  String? actionSurfaceTitle,
  String? actionHeroSubtitle,
  String? actionHeroBody,
  String? actionPanelTitle,
  String? actionPanelBody,
  String? alternateActionLabel,
  String? completeTitle,
  String? completeBody,
  String? receivedTitle,
  String? receivedBody,
  String? completeLabel,
}) {
  return _RichWorkflowSpec(
    layout: layout ?? _inferredRichWorkflowLayout(title, subtitle, detailTitle),
    accent: accent,
    icon: icon,
    title: title,
    subtitle: subtitle,
    body: body,
    facts: facts,
    actionSurfaceTitle: actionSurfaceTitle ?? title,
    actionHeroSubtitle: actionHeroSubtitle ?? subtitle,
    actionHeroBody: actionHeroBody ?? body,
    actionPanelTitle: actionPanelTitle ?? 'Task details',
    actionPanelBody:
        actionPanelBody ??
        'Key fields, status, available edits, and the next visible outcome stay together on this community surface.',
    alternateActionLabel: alternateActionLabel ?? 'Edit details',
    detailTitle: detailTitle,
    detailRows: detailRows,
    stateTitle: stateTitle,
    stateRows: stateRows,
    completeTitle: completeTitle ?? 'Saved',
    completeBody:
        completeBody ?? '$title is saved with visible result and next steps.',
    receivedTitle: receivedTitle ?? '$title ready',
    receivedBody:
        receivedBody ??
        'The recipient can read the saved details, understand what changed, and continue from the next step.',
    completeLabel: completeLabel ?? 'Saved',
  );
}

_RichWorkflowLayout _inferredRichWorkflowLayout(
  String title,
  String subtitle,
  String detailTitle,
) {
  final text = '$title $subtitle $detailTitle'.toLowerCase();
  if (text.contains('export') ||
      text.contains('import') ||
      text.contains('transfer') ||
      text.contains('redaction') ||
      text.contains('checksum') ||
      text.contains('schema')) {
    return _RichWorkflowLayout.exportWizard;
  }
  if (text.contains('search') ||
      text.contains('citation') ||
      text.contains('digest') ||
      text.contains('answer')) {
    return _RichWorkflowLayout.searchAnswer;
  }
  if (text.contains('message') ||
      text.contains('thread') ||
      text.contains('connection') ||
      text.contains('invite') ||
      text.contains('blocked')) {
    return _RichWorkflowLayout.messageThread;
  }
  if (text.contains('announcement') ||
      text.contains('notification') ||
      text.contains('notice') ||
      text.contains('publish')) {
    return _RichWorkflowLayout.noticeDetail;
  }
  if (text.contains('rsvp') ||
      text.contains('event') ||
      text.contains('schedule') ||
      text.contains('reservation') ||
      text.contains('facility') ||
      text.contains('practice') ||
      text.contains('meeting') ||
      text.contains('walk')) {
    return _RichWorkflowLayout.eventDetail;
  }
  if (text.contains('payment') ||
      text.contains('donation') ||
      text.contains('dues') ||
      text.contains('checkout') ||
      text.contains('receipt') ||
      text.contains('settlement') ||
      text.contains('fee')) {
    if (text.contains('ad-off') || text.contains('ad-free')) {
      return _RichWorkflowLayout.adEntitlement;
    }
    return _RichWorkflowLayout.paymentReceipt;
  }
  if (text.contains('ad-off') ||
      text.contains('ad-free') ||
      text.contains('suppression') ||
      text.contains('entitlement')) {
    return _RichWorkflowLayout.adEntitlement;
  }
  if (text.contains('roster') ||
      text.contains('minor') ||
      text.contains('guardian') ||
      text.contains('team')) {
    return _RichWorkflowLayout.rosterProfile;
  }
  if (text.contains('request') ||
      text.contains('approval') ||
      text.contains('decision') ||
      text.contains('committee') ||
      text.contains('review')) {
    return _RichWorkflowLayout.requestReview;
  }
  if (text.contains('critique') ||
      text.contains('camera') ||
      text.contains('photo')) {
    return _RichWorkflowLayout.mediaReview;
  }
  if (text.contains('volunteer') ||
      text.contains('plant') ||
      text.contains('gear') ||
      text.contains('loan') ||
      text.contains('offer') ||
      text.contains('form') ||
      text.contains('care')) {
    return _RichWorkflowLayout.formSubmission;
  }
  if (text.contains('book') ||
      text.contains('vote') ||
      text.contains('nomination') ||
      text.contains('chess') ||
      text.contains('match')) {
    return _RichWorkflowLayout.clubScoreboard;
  }
  return _RichWorkflowLayout.standard;
}

Widget? _domainPreviewPanelFor(
  String workflowId, {
  required Color accent,
  required Color foreground,
}) {
  if (workflowId == 'book-search-ai-digest') {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'AI answer with citations',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.search_outlined,
          title: 'Query',
          body: 'What should we discuss before chapter 6?',
        ),
        _DomainPreviewRow(
          icon: Icons.auto_awesome_outlined,
          title: 'Answer summary',
          body:
              'Mutual aid, scarcity, and Lauren\'s journal voice are the strongest discussion threads.',
        ),
        _DomainPreviewRow(
          icon: Icons.format_quote_outlined,
          title: 'Cited sources',
          body:
              'Member notes, nomination rationale, and March prompt show source labels and visibility.',
        ),
      ],
    );
  }
  if (workflowId == 'book-export-metadata') {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Book club archive',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.menu_book_outlined,
          title: 'Reading records',
          body:
              'Nominations, ballots, selected books, meeting RSVPs, and reading schedule are included.',
        ),
        _DomainPreviewRow(
          icon: Icons.forum_outlined,
          title: 'Discussion redaction',
          body:
              'Private thread metadata and member contact fields are redacted before download.',
        ),
        _DomainPreviewRow(
          icon: Icons.verified_outlined,
          title: 'Checksum BC-042',
          body:
              'Owner sees checksum, export timestamp, download progress, and audit history.',
        ),
      ],
    );
  }
  if (workflowId.contains('photo-walk')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Photo walk details',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.route_outlined,
          title: 'Riverfront golden-hour route',
          body: 'Meet at Dock 4, walk the mural loop, finish at the pier.',
        ),
        _DomainPreviewRow(
          icon: Icons.groups_outlined,
          title: '12 going, 4 spots left',
          body: 'Maybe and Not going stay available until Saturday noon.',
        ),
        _DomainPreviewRow(
          icon: Icons.camera_alt_outlined,
          title: 'Bring 35mm or phone camera',
          body: 'Reminder includes rain plan, gear note, and host contact.',
        ),
      ],
    );
  }
  if (workflowId.contains('critique')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Critique submission',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.image_outlined,
          title: 'Street portrait: â€œEvening Reflectionâ€',
          body: 'Prompt, consent note, and visibility are reviewed together.',
        ),
        _DomainPreviewRow(
          icon: Icons.rate_review_outlined,
          title: 'Reviewer queue',
          body:
              'Avery reviews composition; comments and edit option remain open.',
        ),
        _DomainPreviewRow(
          icon: Icons.swap_horiz_outlined,
          title: 'Edit or withdraw',
          body:
              'Member can update caption, replace image, or withdraw before comments.',
        ),
      ],
    );
  }
  if (workflowId.contains('gear')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Gear loan roster',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.camera_outdoor_outlined,
          title: '35mm prime lens',
          body: 'Owned by Sam; pickup Friday 5 PM and return Sunday evening.',
        ),
        _DomainPreviewRow(
          icon: Icons.people_outline,
          title: '2 borrowers waiting',
          body: 'Borrower list is visible after owner approves the loan.',
        ),
        _DomainPreviewRow(
          icon: Icons.keyboard_return_outlined,
          title: 'Return and cancel option',
          body: 'Member can cancel request, update pickup, or mark returned.',
        ),
      ],
    );
  }
  if (workflowId.startsWith('platform-')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: workflowId.contains('sensitive')
          ? 'Privacy-safe ad suppression'
          : workflowId.contains('banner')
          ? 'Top banner reserved space'
          : workflowId.contains('ad') || workflowId.contains('no-fill')
          ? 'Sponsored message placement'
          : workflowId.contains('blocked')
          ? 'Connection safety guard'
          : 'Member conversation',
      rows: [
        if (workflowId.contains('ad') ||
            workflowId.contains('no-fill')) ...const [
          _DomainPreviewRow(
            icon: Icons.campaign_outlined,
            title: 'Sponsored disclosure',
            body: 'Reserved slot shows sponsor, disclosure, or no-fill reason.',
          ),
          _DomainPreviewRow(
            icon: Icons.visibility_off_outlined,
            title: 'Sensitive context protected',
            body: 'Ad click is hidden when content is protected or suppressed.',
          ),
          _DomainPreviewRow(
            icon: Icons.analytics_outlined,
            title: 'Impression state',
            body:
                'Impression/click is recorded only when an ad is actually filled.',
          ),
        ] else ...const [
          _DomainPreviewRow(
            icon: Icons.person_outline,
            title: 'Maya Chen -> Jordan Lee',
            body:
                'Visible sender, recipient, Today 9:12 AM timestamp, and community relationship.',
          ),
          _DomainPreviewRow(
            icon: Icons.message_outlined,
            title: 'Message body',
            body:
                'Invite says: "Want to coordinate the Saturday welcome table together?"',
          ),
          _DomainPreviewRow(
            icon: Icons.block_outlined,
            title: 'Decision and safety options',
            body:
                'Accept, decline, cancel, mute, archive, block, or unblock remain visible where allowed.',
          ),
        ],
      ],
    );
  }
  if (workflowId.startsWith('ad-off-')) {
    final title = workflowId.contains('receipt')
        ? 'Receipt history'
        : workflowId.contains('suppression')
        ? 'Ad suppression proof'
        : workflowId.contains('entitlement')
        ? 'Subscription status'
        : workflowId.contains('settlement')
        ? 'Settlement allocation'
        : workflowId.contains('community')
        ? 'Community checkout'
        : 'Member checkout';
    final rows = workflowId.contains('receipt')
        ? const [
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Receipt ADO-1042',
              body:
                  'Amount, payer, paid date, scope, refund support, and export trail are visible.',
            ),
            _DomainPreviewRow(
              icon: Icons.download_outlined,
              title: 'Export and support',
              body:
                  'Member can export the receipt or open support history without returning to checkout.',
            ),
            _DomainPreviewRow(
              icon: Icons.verified_user_outlined,
              title: 'Linked entitlement',
              body:
                  'Receipt links directly to current ad-free entitlement and restore option.',
            ),
          ]
        : workflowId.contains('suppression')
        ? const [
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Suppressed top banner',
              body:
                  'No ad rendered; no impression or click recorded for the active entitlement.',
            ),
            _DomainPreviewRow(
              icon: Icons.dynamic_feed_outlined,
              title: 'Suppressed stream slot',
              body:
                  'The stream explains why sponsored content is hidden without exposing private data.',
            ),
            _DomainPreviewRow(
              icon: Icons.restore_outlined,
              title: 'Restore/manage option',
              body:
                  'Member can restore ads or manage ad-off from the same proof screen.',
            ),
          ]
        : workflowId.contains('entitlement')
        ? const [
            _DomainPreviewRow(
              icon: Icons.verified_user_outlined,
              title: 'Active through Aug 30',
              body:
                  'Subscription state, renewal, receipt, and plan scope are visible.',
            ),
            _DomainPreviewRow(
              icon: Icons.restore_outlined,
              title: 'Manage or restore',
              body:
                  'Member can manage plan, restore purchase, or open receipt history.',
            ),
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Ad-free member view',
              body: 'Eligible banner and stream slots remain suppressed.',
            ),
          ]
        : workflowId.contains('settlement')
        ? const [
            _DomainPreviewRow(
              icon: Icons.account_balance_outlined,
              title: 'Utility allocation',
              body:
                  'Community utility fund destination, amount, and month-end status are visible.',
            ),
            _DomainPreviewRow(
              icon: Icons.history_outlined,
              title: 'Audit trail',
              body:
                  'Settlement run, receipts, and rollback/correction option are linked.',
            ),
            _DomainPreviewRow(
              icon: Icons.verified_outlined,
              title: 'Owner action',
              body:
                  'Owner can verify or correct allocation before final settlement.',
            ),
          ]
        : const [
            _DomainPreviewRow(
              icon: Icons.payments_outlined,
              title: 'Plan details',
              body:
                  'Payer, amount, payment method, renewal, and scope are confirmed before purchase.',
            ),
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Receipt after checkout',
              body:
                  'Purchase creates receipt evidence and immediate entitlement record.',
            ),
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Ads hidden after payment',
              body:
                  'Eligible sponsored slots show a suppressed state with manage/restore controls.',
            ),
          ];
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: title,
      rows: rows,
    );
  }
  if (workflowId.startsWith('export-')) {
    final title =
        workflowId.contains('import-preview') ||
            workflowId.contains('import-replay')
        ? 'Legacy import preview'
        : workflowId.contains('full-bundle') ||
              workflowId.contains('redacted-bundle')
        ? 'Downloadable export bundle'
        : workflowId.contains('transfer-verification')
        ? 'Provider transfer verification'
        : workflowId.contains('protected-redaction')
        ? 'Protected-field redaction'
        : workflowId.contains('transfer-rollback')
        ? 'Rollback and recovery'
        : workflowId.contains('schema-listing')
        ? 'Exportable schema catalog'
        : workflowId.contains('checksum')
        ? 'Checksum evidence'
        : 'Portability task';
    final rows =
        workflowId.contains('import-preview') ||
            workflowId.contains('import-replay')
        ? const [
            _DomainPreviewRow(
              icon: Icons.preview_outlined,
              title: 'Import rows',
              body:
                  'Preview 48 member rows, 22 documents, and 12 receipts before replay.',
            ),
            _DomainPreviewRow(
              icon: Icons.warning_amber_outlined,
              title: 'Conflict check',
              body:
                  'Three duplicate records are flagged with accept/skip choices.',
            ),
            _DomainPreviewRow(
              icon: Icons.history_outlined,
              title: 'Replay log',
              body:
                  'Owner sees import checkpoint, retry option, and rollback marker.',
            ),
          ]
        : workflowId.contains('transfer-verification')
        ? const [
            _DomainPreviewRow(
              icon: Icons.cloud_sync_outlined,
              title: 'Destination provider',
              body:
                  'Provider receives bundle E-204 after checksum and scope match.',
            ),
            _DomainPreviewRow(
              icon: Icons.verified_outlined,
              title: 'Handshake',
              body:
                  'Source hash, destination hash, and received timestamp must match.',
            ),
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Transfer receipt',
              body:
                  'Owner gets receipt, provider ID, audit log, and next action.',
            ),
          ]
        : workflowId.contains('protected-redaction')
        ? const [
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Protected fields',
              body:
                  'Care notes, phone numbers, and private vault values are masked.',
            ),
            _DomainPreviewRow(
              icon: Icons.rule_outlined,
              title: 'Policy reason',
              body:
                  'Each redaction lists the policy and the actor identity allowed to reveal it.',
            ),
            _DomainPreviewRow(
              icon: Icons.preview_outlined,
              title: 'Before/after preview',
              body:
                  'Owner compares raw labels with exported safe values before download.',
            ),
          ]
        : workflowId.contains('transfer-rollback')
        ? const [
            _DomainPreviewRow(
              icon: Icons.undo_outlined,
              title: 'Rollback checkpoint',
              body:
                  'Last good snapshot is retained until destination provider confirms.',
            ),
            _DomainPreviewRow(
              icon: Icons.error_outline,
              title: 'Mismatch reason',
              body:
                  'Destination checksum mismatch triggers retry, cancel, or rollback.',
            ),
            _DomainPreviewRow(
              icon: Icons.history_outlined,
              title: 'Recovery audit',
              body:
                  'Owner sees who started rollback, timestamp, and restored scope.',
            ),
          ]
        : workflowId.contains('schema-listing')
        ? const [
            _DomainPreviewRow(
              icon: Icons.schema_outlined,
              title: 'Schema catalog',
              body:
                  'community, member, receipt, document, message, and custom tables are listed.',
            ),
            _DomainPreviewRow(
              icon: Icons.key_outlined,
              title: 'Field classes',
              body:
                  'Each schema shows public, member, protected, payment, and audit fields.',
            ),
            _DomainPreviewRow(
              icon: Icons.download_outlined,
              title: 'Export coverage',
              body:
                  'Owner can include, exclude, or open schema history before export.',
            ),
          ]
        : workflowId.contains('checksum')
        ? const [
            _DomainPreviewRow(
              icon: Icons.verified_outlined,
              title: 'Checksum 9A7F-PORT',
              body:
                  'SHA-256 digest, file count, and byte size are visible before delivery.',
            ),
            _DomainPreviewRow(
              icon: Icons.compare_arrows_outlined,
              title: 'Verify again',
              body: 'Owner can rerun verification after transfer or download.',
            ),
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Integrity receipt',
              body: 'Checksum receipt links to export scope and audit history.',
            ),
          ]
        : const [
            _DomainPreviewRow(
              icon: Icons.folder_zip_outlined,
              title: 'Bundle contents',
              body:
                  'Members, receipts, documents, messages, and custom records are packaged.',
            ),
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Redaction preview',
              body:
                  'Protected fields are masked and counted before bundle generation.',
            ),
            _DomainPreviewRow(
              icon: Icons.file_download_outlined,
              title: 'Download state',
              body:
                  'Owner sees size, checksum, download progress, and next transfer step.',
            ),
          ];
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: title,
      rows: rows,
    );
  }
  return null;
}
