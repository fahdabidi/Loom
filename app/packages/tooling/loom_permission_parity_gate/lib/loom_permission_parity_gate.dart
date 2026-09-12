/// The permission-parity gate: the expected side comes from App Access's
/// read-only `community-permission-exports`, the actual side from live
/// `role_permission` rows, and the comparison is over **exact permission-id
/// sets** -- not counts, because swapping one wrong permission preserves the
/// count.
///
/// **What this gate is for.** `check_role_parity.sh` compares role
/// *existence*, which is why it passed throughout the Masjid incident: on
/// 2026-09-05 a package regeneration renamed `masjid-admin` to `owner`, the
/// old role kept its 23 permissions and kept working, and the new one was
/// never created. Nothing failed. This gate compares the permission sets
/// themselves, so a role holding the wrong set is a failure even when every
/// role exists.
///
/// **What it is not.** It **detects** drift; it does not prevent it. Nothing
/// stops a deployment because of this gate unless the deployment depends on it
/// passing. Write-time enforcement is a separate, already-landed concern.
///
/// **It never writes.** The expected side is one read-only export call per
/// community; the actual side is one read of `role_permission`. There is no
/// create, no grant, no reconcile -- see `permission_progress_analysis.dart`
/// for why a node must never grant.
library;

export 'src/comparison.dart';
export 'src/export_client.dart';
export 'src/gate_cli.dart';
export 'src/live_reader.dart';
export 'src/package_loader.dart';
