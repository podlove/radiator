# ADR 0002 – The Organizer decides; Members can take over

- **Status**: Accepted
- **Date**: 2026-11-10
- **Supersedes**: [ADR 0001](./0001-episode-scheduling.md) §1 (who decides) and the remove_proposal,
  finalize, reopen and destroy rows of §5

ADR 0001 let every Member of the podcast finalize and reopen a Scheduling, rejecting a single owner
because one breaks when that user leaves. In practice that let one Member pick the date of a
Scheduling another Member was running. Now the **Organizer** (the Member who started the Scheduling)
alone finalizes, reopens, removes other people's Proposals and deletes it, and only while still a
Member. The "owner leaves" problem is solved with an explicit **take over** instead of shared powers:
when the Organizer is gone (no longer a Member, or account deleted), any Member may take over and
become the Organizer, in open and closed state alike.

## Rules

| Action | Allowed |
| --- | --- |
| start | Member; becomes the Organizer and a Participant |
| add_proposal | Member or Participant |
| remove_proposal | Organizer (any Proposal); anybody else only their own |
| vote, remove_vote | Participant (own Vote only) |
| finalize, reopen, destroy | Organizer, while a Member |
| take_over | Member, only while the Organizer is gone; becomes the Organizer and a Participant |

## Considered options

- **Every Member decides** (ADR 0001): rejected, it lets Members overrule each other silently.
- **When the Organizer is gone, every Member decides**: rejected, it brings back the free-for-all
  exactly when nobody is accountable.
- **Accept a stuck Scheduling, delete and restart**: rejected, it loses every Vote.

## Consequences

- An Organizer removed from the podcast keeps voting as long as they are credited as a Contributor;
  they only lose the Organizer powers.
- No notification on take-over in v1; the page shows who the Organizer is.
