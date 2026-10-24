# ADR 0001 – Episode Scheduling & Availability Voting

- **Status**: Accepted
- **Date**: 2026-10-24
- **Context documents**: [spec](../specs/episode-scheduling/README.md),
  [implementation plan](../plans/episode-scheduling.md)

## Context

Every hand-created episode starts by finding a recording date: proposals are made, every contributor
marks yes / maybe / no, and somebody decides with the help of a ranking. A first implementation exists
on the legacy branch `feature/create-with-participants`; it was built on a domain model that `main`
no longer has (personas, episode participants, a scheduling owner persona, an episode state machine,
an admin episode show page).

On `main`:

- `Radiator.Podcasts.Person` belongs to the podcast owner who files it (`user_id`) and may be linked to
  the login it *is* (`account_id`).
- `Radiator.Podcasts.EpisodeContributor` links persons to episodes; contributors can be invited by email,
  which creates or links an account (PR #644).
- Access to a podcast is governed by membership (`PodcastUserRole`, `podcast.users`).
- `Episode` has no lifecycle state; feed-imported episodes are already published.
- The admin area has only an episode *form*; the podcast `:read` action is members-only.

The decisions below adapt the spec to this model.

## Decisions

### 1. Who decides and who votes

**Podcast members decide; contributors with an account vote.**

- Any podcast member may start a scheduling, add or remove any proposal, finalize and reopen.
- The voters ("participants" in the spec) are the episode's contributors whose person has an
  `account_id`. Contributors without an account (e.g. from the feed) are not listed.
- A signed-in user votes as the contributor person with `person.account_id == actor.id`.
- Actions take **no `persona_id`/`person_id` argument**; the acting person is resolved from the actor.

*Alternatives:* a single owner (the user who started the poll) — rejected, membership already models
"may manage this podcast" and a single owner breaks when that user leaves; listing contributors without
account as always-pending rows — rejected, they can never answer and would distort `all_voted?`.

*Consequences:* no `participant_persona_ids` list to keep in sync (legacy gap #1 disappears); the voter
list changes automatically with the contributor list; votes of removed contributors stay stored but
are ignored by the statistics.

### 2. Storage: embedded proposals and votes

**Proposals and votes are embedded (JSONB array) in one `episode_schedulings` row**, as in legacy.

*Alternatives:* separate `scheduling_proposals` / `scheduling_votes` tables with a unique
`(proposal_id, person_id)` index — would allow atomic upserts and avoid lost updates.

*Why embedded:* straight port of proven legacy logic, the whole poll is read and rendered at once,
polls are small (a handful of proposals × contributors).

*Consequences:* updates are read-modify-write (`require_atomic? false`); two simultaneous votes on the
same scheduling can overwrite each other. Accepted for v1; revisit (optimistic locking or tables) if it
shows up in practice.

### 3. Episode lifecycle: state machine

**`Episode` gets an `AshStateMachine` `state`: `:scheduling | :scheduled | :published`.**

- Hand-created episodes start in `:scheduling`; feed upserts set `:published`; existing rows are
  backfilled (`:published` if seen in the feed or having `published_at`, otherwise `:scheduling`).
- `finalize` on the scheduling transitions the episode `:scheduling → :scheduled`, `reopen` transitions
  it back — **in the same transaction**, so scheduling status and episode state cannot diverge.
- The chosen date is stored only in `scheduling.chosen_datetime`; no `Episode.recording_at`, and
  `publication_date`/`published_at` is **not** misused for the recording date (legacy gap #3).

*Alternative:* derive "scheduled" from the scheduling status without an episode state — rejected in
favour of an explicit lifecycle that later phases (recording, publishing) can extend.

### 4. A dedicated scheduling page

**New LiveView `/admin/podcasts/:podcast_id/episodes/:id/scheduling`**, readable by members and the
episode's contributors. Proposals are managed there and take effect immediately (not via the episode
form). The contributor invitation mail links to this page.

*Why:* the episode edit page loads the podcast with the members-only `:read` policy, so invited
contributors who are not members cannot open it. The scheduling page loads the podcast via
`:public_read` and authorizes through the scheduling's own policies.

### 5. Authorization through Ash policies

All scheduling actions are guarded by policies on the resource (not by ad-hoc validations):

| Action | Allowed |
| --- | --- |
| read | member or contributor |
| start | member |
| add_proposal | member or contributor |
| remove_proposal | member, or contributor who created the proposal |
| vote, remove_vote | contributor (own vote only) |
| finalize, reopen | member |

This closes legacy gap #2 (only `vote` checked the actor).

### 6. Ranking rules

Ranking is computed on read by a pure `Stats` module: order by total score desc, then yes-count desc,
no-count asc, datetime asc. `top_proposal_id` is `nil` on a tie in total score. `all_voted?` means no
pending cell. The owner's choice is free; the ranking is advisory.

### 7. Time zones

The browser's time zone is sent as a LiveSocket connect param; inputs are converted to UTC and dates
are rendered in the viewer's zone, using `tz` as the Calendar time zone database (fallback
`Europe/Berlin`). UI strings follow the project's convention of German gettext msgids.

### 8. Delivery

Implemented in six phases, one stacked branch and PR each (see the plan). Each phase is reviewed before
the next one starts.

## Out of scope (v1)

Notifications beyond the existing contributor invitation, realtime updates (PubSub), vote comments in
the UI, deadlines, iCal export, public voting links for people without an account.
