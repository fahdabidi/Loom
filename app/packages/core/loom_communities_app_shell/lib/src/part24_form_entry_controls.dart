part of loom_communities_app_shell;

const _reminderOffsets = <String, Duration>{
  'at-time': Duration.zero,
  'one-hour': Duration(hours: 1),
  'one-day': Duration(days: 1),
  'one-week': Duration(days: 7),
};

String _reminderOffsetLabel(String value) => switch (value) {
  'at-time' => 'At the time',
  'one-hour' => '1 hour before',
  'one-day' => '1 day before',
  'one-week' => '1 week before',
  _ => value,
};
