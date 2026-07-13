part of loom_communities_app_shell;

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.event, required this.drawLine});
  final LoomStatusTimelineEvent event;
  final bool drawLine;

  @override
  Widget build(BuildContext context) => Row(
    key: ValueKey('status-timeline-node-${event.eventId}'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: 28,
        child: Column(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xff246b62),
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 14, height: 14),
            ),
            if (drawLine)
              Expanded(
                child: Container(
                  key: ValueKey('status-timeline-line-${event.eventId}'),
                  width: 2,
                  color: const Color(0xff246b62),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.timestamp.toIso8601String(),
                key: ValueKey('status-timeline-time-${event.eventId}'),
              ),
              const SizedBox(height: 3),
              Text(
                event.label,
                key: ValueKey('status-timeline-label-${event.eventId}'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
