/// The only community-package specification version supported by the app,
/// workflow engine/service, and package tooling.
///
/// Source of truth: `docs/references/spec-version.json` (`current`). A test
/// reads that file directly so this hand-written constant cannot drift
/// silently.
const int currentCommunitySpecVersion = 4;
