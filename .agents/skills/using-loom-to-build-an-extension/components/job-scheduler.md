# Job Scheduler

Use `CommunityJobSchedulerApi` for scheduled or delayed rule triggers.

## Extension Use

- Use jobs for time-based triggers, not synchronous UI actions.
- Trigger rules rather than service internals.
- Keep job idempotency keys stable for retries.

## Validation

- `vt_job-scheduler_trigger` proves job trigger state.
- `ct_job-scheduler__rule-engine_trigger` proves job-to-rule handoff.
