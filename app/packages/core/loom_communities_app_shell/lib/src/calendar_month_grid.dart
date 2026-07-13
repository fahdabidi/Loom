part of loom_communities_app_shell;

class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    super.key,
    required this.workflows,
    required this.onSelect,
  });
  final List<LoomWorkflowDefinition> workflows;
  final ValueChanged<String>? onSelect;
  @override
  Widget build(BuildContext context) {
    final anchor = workflows
        .map((w) => w.calendarItem!.dateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final first = DateTime(anchor.year, anchor.month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    final byDay = <String, List<LoomWorkflowDefinition>>{};
    for (final workflow in workflows) {
      byDay
          .putIfAbsent(_isoDateKey(workflow.calendarItem!.dateTime), () => [])
          .add(workflow);
    }
    return Column(
      key: const ValueKey('calendar-month-grid'),
      children: [
        Text(
          '${_monthLabel(first.month)} ${first.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Row(
          children: [
            for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
              Expanded(child: Center(child: Text(day))),
          ],
        ),
        for (var week = 0; week < 6; week++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var weekday = 0; weekday < 7; weekday++)
                Builder(
                  builder: (context) {
                    final day = start.add(Duration(days: week * 7 + weekday));
                    final key = _isoDateKey(day);
                    final events =
                        byDay[key] ?? const <LoomWorkflowDefinition>[];
                    return Expanded(
                      child: Container(
                        key: ValueKey('calendar-day-cell-$key'),
                        constraints: const BoxConstraints(minHeight: 92),
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${day.day}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            if (events.isNotEmpty)
                              SizedBox(
                                height: 62,
                                child: RepeaterSurface.static(
                                  items: events,
                                  itemBuilder: (context, item) {
                                    final event =
                                        item as LoomWorkflowDefinition;
                                    return InkWell(
                                      key: ValueKey(
                                        'calendar-grid-event-${event.workflowId}',
                                      ),
                                      onTap: () =>
                                          onSelect?.call(event.workflowId),
                                      child: Text(
                                        _displayTitleFor(event),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}
