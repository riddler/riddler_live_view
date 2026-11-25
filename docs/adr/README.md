# Architecture Decision Records

| # | Decision | Status |
|---|---|---|
| [0001](0001-what-the-package-is.md) | RiddlerLiveView renders what Riddler presents, owns no state and steps nothing | proposed |

New ADRs: next number, the sections riddler's records carry (Context,
Decision, Consequences, and the typespecs and worked-example section). Pick
the number against a freshly fetched remote.

This repository follows riddler's record practice rather than restating it:
how a record grows by dated Notes and Amendments, which passage governs, and
when an entry is a Note or an Amendment are as riddler's
[`docs/adr/README.md`](https://github.com/riddler/riddler-ex/blob/v0.8.0/docs/adr/README.md)
says at `v0.8.0`. A bare `ADR-NNNN` cites this repository's own records; a
cross-repo citation carries the owning repository's beads prefix, so
`rd-ADR-0005` is riddler's ADR-0005 and `rlv-ADR-0001` is how another
repository cites this one's ADR-0001.

A dated provenance line in these records reads "Noted YYYY-MM-DD", or
"ruled by the operator, YYYY-MM-DD", or restates the reason (`CLAUDE.md`,
"Conventions"), or, for a decision taken under a standing consent of the
maintainer's, "decided by the conductor under a standing consent,
YYYY-MM-DD".
