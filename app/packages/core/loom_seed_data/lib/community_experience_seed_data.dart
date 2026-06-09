class CommunityExperienceSeed {
  const CommunityExperienceSeed({
    required this.threadId,
    required this.formId,
    required this.pollId,
  });

  final String threadId;
  final String formId;
  final String pollId;
}

const communityExperienceSeed = CommunityExperienceSeed(
  threadId: 'thread_book_club_general',
  formId: 'form_book_nomination',
  pollId: 'poll_next_book',
);
