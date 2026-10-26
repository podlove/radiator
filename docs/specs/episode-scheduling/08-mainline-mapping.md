# 08 – Mapping to `main`

The spec (01–07) was written against the legacy branch `feature/create-with-participants`. This file
maps it to the implementation on `main` (PRs #645–#650). Rationale: [ADR 0001](../../adrs/0001-episode-scheduling.md).

## Terms

| Spec | `main` |
| --- | --- |
| Persona | `Radiator.Podcasts.Person`; the signed-in user is the person with `account_id == user.id` |
| Persona ↔ User (`personas.user_id`) | `persons.account_id` (`persons.user_id` is the podcast owner who files the person) |
| Episode participant | `Radiator.Podcasts.EpisodeContributor` |
| Scheduling participant (`participant_persona_ids`) | derived, not stored: contributors whose person has an account (`Person :scheduling_participants`) |
| Owner (`owner_persona_id`) | any member of the podcast (`PodcastUserRole`); the starter is kept as `created_by` and added as a contributor, so they vote |
| `persona_id` arguments | none — the acting person is resolved from the actor (`Scheduling.Voter`) |
| `Proposal.created_by_persona_id` | `Proposal.created_by_user_id` |
| `Vote.persona_id` | `Vote.person_id` |
| Episode states `:creation → :scheduling → :scheduled` | `:scheduling → :scheduled`, plus `:published` for feed episodes; no `:creation` |
| Episode show page with matrix | dedicated page `/admin/podcasts/:podcast_id/episodes/:id/scheduling` |
| Proposals in the episode form | proposals are managed on the scheduling page and saved immediately |

## Where things live

| Concern | Module |
| --- | --- |
| Episode lifecycle | `Radiator.Podcasts.Episode` (`state_machine`) |
| Scheduling resource and actions | `Radiator.Podcasts.Episode.Scheduling` |
| Embedded proposal / vote | `…Scheduling.Proposal`, `…Scheduling.Vote` |
| List operations | `…Scheduling.Proposals` |
| Who votes / roles | `…Scheduling.Voter`, `…Scheduling.Access` |
| Authorization | `…Scheduling.Policies`, `…Scheduling.Checks.*` |
| Ranking | `…Scheduling.Stats` |
| Page | `RadiatorWeb.Admin.EpisodeLive.Scheduling` (+ `SchedulingHelpers`) |
| Domain functions | `Radiator.Podcasts.start_scheduling/3`, `vote_on_proposal/4`, `finalize_scheduling/3`, … |

## Deviations from the spec text

- Ranking tie-breakers: total score, yeses, date. "Fewer noes" is implied (spec 03 updated).
- Error messages are lower-case English on the resource; the page shows German flash messages.
- Score range is enforced by argument constraints (`-1..1`), not a `ValidScore` validation.
- Some refusals surface as `Ash.Error.Invalid` rather than `Forbidden`, because Ash runs changes and
  validations before policies (vote by a non-contributor, removing another's proposal, start without actor).
- `remove_vote` exists but has no button in the UI (as in spec 05 §2.2).
- Vote comments are stored but not shown (out of scope v1).

## Gaps from 07 and their status

| # | Gap | Status |
| --- | --- | --- |
| 1 | Participants not filled from the form | solved: derived from contributors |
| 2 | Actor check only on `vote` | solved: policies on every action |
| 3 | Episode state not coupled | solved: same transaction; `:creation` dropped; no `recording_at` |
| 4 | Time zones / localization | solved: browser zone, `tz`; German gettext msgids |
| 5 | Ranking ties | solved |
| 6 | `all_voted?` semantics | solved |
| 7 | Weak input validation | solved, except past dates (still accepted) |
| 8 | Duplicated code | solved |
| 9 | Owner not a participant | solved: the member who starts the scheduling is added as a contributor (`host`) and votes; other members vote only if they contribute |
| 10 | Concurrency of embedded votes | accepted for v1 (ADR 0001 §2) |
| 11 | Votes of removed participants | solved: ignored by `Stats` |
| 12 | Owner UI missing | solved |
