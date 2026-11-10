# Plan: Episode Scheduling & Availability Voting

## Context

The scheduling/voting feature exists only on the legacy branch; its intended behavior is specified in
`docs/specs/episode-scheduling/`. The main branch has a different domain model:

| Spec (legacy) | Current branch |
| --- | --- |
| Persona (`Radiator.People.Persona`, `user_id`) | `Radiator.Podcasts.Person` — `user_id` = podcast owner who files the record, `account_id` = the login this person *is* |
| Episode participants (`EpisodeParticipant`) | `Radiator.Podcasts.EpisodeContributor` (`episode_id`, `person_id`, `role`; no uniqueness) |
| Scheduling owner persona | Podcast members (`PodcastUserRole`, relation `podcast.users`) |
| Episode state machine | none — `Episode` has no `state`; feed episodes are already published |
| Admin episode show page | none — only `EpisodeLive.Form` (`/admin/podcasts/:podcast_id/episodes/:id/edit`) |

Step 1 of the feature (inviting contributors by email, `NotifyNewContributors` +
`SendContributorEmail`) is done (PR #644). This plan covers everything after it.

**Decisions (from user)**
- Podcast **members decide** (start, manage any proposal, finalize, reopen); **contributors with an
  account vote**. The actor votes as the episode contributor whose `person.account_id == actor.id`.
  Contributors without an account are not listed.
- **Embedded JSONB** storage for proposals/votes (port of legacy).
- **Add an episode state machine** (`ash_state_machine` is already a dependency).
- **Dedicated scheduling page**, readable by members and contributors; the invite mail links there.
- No `Episode.recording_at`: the chosen date lives in `scheduling.chosen_datetime`.
- One branch and PR per phase, **stacked** (phase N targets the phase N-1 branch). Review after each PR.
- Rationale for all choices: [ADR 0001](../adrs/0001-episode-scheduling.md).

Mapping of spec concepts: "participant" = contributor person with account; "owner" = any podcast member;
`persona_id` arguments are dropped — the acting person is resolved from the actor (spec 07 #2).
UI strings follow this branch's convention: German msgids in `gettext`.

---

## Phase 1 — Episode state machine

`lib/radiator/podcasts/episode.ex`
- `extensions: [AshStateMachine]`; states `:scheduling | :scheduled | :published`,
  `initial_states [:scheduling, :published]`, `default_initial_state :scheduling`.
- Transitions: `finalize_scheduling` (`:scheduling → :scheduled`), `back_to_scheduling`
  (`:scheduled → :scheduling`). Update actions with `change transition_state(...)`; no code interface
  (called only by the scheduling actions).
- `:upsert_from_feed` sets `state: :published` (`change set_attribute(:state, :published)`), keep it in `upsert_fields`.
- `mix ash.codegen add_episode_state` → migration; add a backfill
  `UPDATE episodes SET state = 'published' WHERE last_seen_in_feed_at IS NOT NULL OR published_at IS NOT NULL`.

Tests (`test/radiator/podcasts/episode_state_test.exs`): hand-created episode starts `:scheduling`;
feed upsert yields `:published`; transitions and invalid transitions.

## Phase 2 — Scheduling resource (embedded proposals/votes)

New files under `lib/radiator/podcasts/episode/scheduling/` (port from legacy, adapted):

- `scheduling.ex` — `Radiator.Podcasts.Episode.Scheduling`, table `episode_schedulings`,
  `authorizers: [Ash.Policy.Authorizer]`.
  - Attributes: `status (:open|:closed)`, `proposals {:array, Proposal}`, `chosen_proposal_id`,
    `chosen_datetime`, `published_at`, `finalized_at`, timestamps.
  - Relationships: `belongs_to :episode` (unique identity `"episode already has a scheduling"`,
    `on_delete: :delete`), `belongs_to :created_by, User` (nilify).
  - `Episode`: add `has_one :scheduling`.
- `proposal.ex` — embedded: `id`, `datetime`, `created_by_user_id`, `votes {:array, Vote}`, timestamps.
  Helpers `vote_by_person/2`. (No `add_vote` duplicate, no `average_score` — spec 07 #8.)
- `vote.ex` — embedded: `person_id`, `score` (−1..1), `voted_at`, `comment`.

Actions (all `require_atomic? false`, actor required):

| Action | Args | Validations / changes |
| --- | --- | --- |
| `:start` (create) | `episode_id`, `proposed_datetimes` | `ProposedDatetimesPresent`; episode `state == :scheduling`; proposals created by actor; `status :open`, `published_at` |
| `:add_proposal` | `datetime` | open; `NoDuplicateDatetime`; `created_by_user_id = actor` |
| `:remove_proposal` | `proposal_id` | open; `ProposalExists`; `MemberOrProposalCreator` |
| `:vote` | `proposal_id`, `score`, `comment?` | open; `ValidScore`; `ProposalExists`; `SetVoter` change (resolves actor's contributor person, error *"Du bist kein Contributor dieser Episode"*); replace semantics |
| `:remove_vote` | `proposal_id` | open; `ProposalExists`; `SetVoter`; removes only own vote |
| `:finalize` | `chosen_proposal_id` | open; `ProposalExists`; sets closed/chosen_*/finalized_at; `after_action` runs `Episode :finalize_scheduling` (same transaction) |
| `:reopen` | – | closed; clears chosen_*/finalized_at; `after_action` runs `Episode :back_to_scheduling` |
| `:read`, `:by_episode` | `episode_id` | |

Reused/ported validations (`.../scheduling/validations/`): `ValidScore`, `ProposedDatetimesPresent`,
`ProposalExists` (generalized with `argument:` option, replaces legacy `ProposalExists` +
`ProposalOwnerOrCreator` lookup). New: `NoDuplicateDatetime`, `MemberOrProposalCreator`.
New change `SetVoter` and helper `Scheduling.voter_person(episode_id, actor)` /
`Scheduling.participants(episode_id)` = distinct contributor persons with `account_id` not nil, sorted by name.

Domain (`lib/radiator/podcasts.ex`): register resource with code interface
`start_scheduling`, `get_scheduling_by_episode`, `add_scheduling_proposal`, `remove_scheduling_proposal`,
`vote_on_proposal`, `remove_vote`, `finalize_scheduling`, `reopen_scheduling`.

Migration via `mix ash.codegen add_episode_schedulings`.

## Phase 3 — Authorization

`lib/radiator/podcasts/episode/scheduling/policies.ex` (Spark fragment, same style as
`lib/radiator/podcasts/podcast/policies.ex`), plus checks in `.../scheduling/checks/`:

- `member` = `relates_to_actor_via([:episode, :podcast, :users])`
- `contributor` = `expr(exists(episode.contributors, person.account_id == ^actor(:id)))`
- `ActorIsMemberOfEpisodePodcast` (SimpleCheck for `:start`, reads `episode_id` from the changeset)

| Action | Allowed |
| --- | --- |
| read | member or contributor |
| start | member |
| add_proposal, remove_proposal | member or contributor (creator rule in validation) |
| vote, remove_vote | contributor |
| finalize, reopen | member |

Tests: `test/radiator/podcasts/episode/scheduling_policies_test.exs` — matrix of spec 04 incl.
stranger, member, contributor with/without account, and "cannot vote as another person".

## Phase 4 — Ranking & statistics

`lib/radiator/podcasts/episode/scheduling/stats.ex` — pure functions, no DB:
`voting_stats(scheduling, participant_person_ids)`, `top_proposal_id/2`, `winner_proposal_id/2`.
Implements spec 03: per-proposal counts, only current participants counted, ranking tie-break
(total desc, yes desc, datetime asc), `top_proposal_id` nil on tie, `all_voted?` = no pending cell.
Port logic from legacy `Scheduling.voting_stats/1` and `AvailabilityHelpers.winner_proposal_id/2`.

Tests: `test/radiator/podcasts/episode/scheduling/stats_test.exs` incl. the worked example of spec 03 §6.

## Phase 5 — Scheduling page (LiveView)

Route in the authenticated live session (`lib/radiator_web/router.ex`):
`live "/podcasts/:podcast_id/episodes/:id/scheduling", EpisodeLive.Scheduling, :show`

`lib/radiator_web/live/admin/episode_live/scheduling.ex` + `.html.heex`:
- mount: podcast via `Podcasts.public_get_podcast_by_id` (contributors aren't members, so the members-only
  `:read` can't be used); episode filtered by `podcast_id`; scheduling via `get_scheduling_by_episode`
  with actor → forbidden/not found ⇒ redirect `/admin` with flash. Assign `member?`, `current_person`,
  `participants`, `stats`, `timezone`.
- No scheduling yet: members see "Terminfindung starten" (one or more dates); others see a hint.
- Proposals: "Termin vorschlagen" (datetime-local) for member/contributor; remove button on own proposals
  (members: all) — spec 05 §2.3 "optional" features become real here; proposals take effect immediately (todo).
- Availability matrix: port legacy `show_live.html.heex` table + `AvailabilityHelpers`
  (→ `lib/radiator_web/live/admin/episode_live/availability_helpers.ex`), rows = participants,
  "(du)" marker, vote buttons with stable DOM ids from spec 05 §2.4, weekday labels via gettext.
- Member panel: ranking list (stats order, counts, tie/pending hints), "Diesen Termin wählen"
  (`data-confirm`) → finalize, "Terminfindung wieder öffnen" → reopen; "Gewählt" badge when closed.
- Time zones: send browser time zone as LiveSocket connect param (`assets/js/app.js`,
  `Intl.DateTimeFormat().resolvedOptions().timeZone`), add `{:tz, ...}` as Calendar time-zone database;
  convert input naive → UTC and render UTC → viewer zone; fallback `"Europe/Berlin"`.

Links:
- `lib/radiator/podcasts/episode/senders/send_contributor_email.ex`: link to `/scheduling` instead of `/edit`
  (update `test/radiator/podcasts/contributor_notification_test.exs`).
- `lib/radiator_web/live/admin/podcast_live/show.html.heex`: per-episode "Terminfindung" link/badge for
  episodes in `:scheduling`/`:scheduled`.
- `episode_live/form.html.heex`: link to the scheduling page in the header (edit mode).

Tests: `test/radiator_web/live/episode_scheduling_test.exs` — spec 06 sections I + owner controls:
member starts scheduling, contributor votes (yes → no flip, footer), stranger is redirected,
contributor without vote rights sees read-only matrix, closed state disables buttons + "Gewählt",
manipulated score → flash, no write; invite-mail link opens the page for a non-member contributor.

## Phase 6 — Seeds & docs

- `priv/repo/seeds.exs`: an episode in `:scheduling` with contributors that have accounts, a scheduling
  with 3 proposals and some votes.
- Add `docs/specs/episode-scheduling/08-mainline-mapping.md` with the mapping table and decisions above;
  remove the stray `SCHEDULING_*.md` / `todo` files once ported (ask first).

## Order & dependencies

1 → 2 → 3 → 4 → 5 → 6, one stacked branch/PR each:

| Phase | Branch |
| --- | --- |
| 1 | `feature/scheduling-1-episode-state` (also un-ignores `docs/`, adds specs, this plan and ADR 0001) |
| 2 | `feature/scheduling-2-resource` |
| 3 | `feature/scheduling-3-policies` |
| 4 | `feature/scheduling-4-stats` |
| 5 | `feature/scheduling-5-page` |
| 6 | `feature/scheduling-6-seeds` |

Each phase ends green with `mix precommit`.

## Status

| Phase | PR |
| --- | --- |
| 1 | #645 |
| 2 | #646 |
| 3 | #647 |
| 4 | #648 |
| 5 | #649 |
| 6 | #650 |
| 7 (follow-up: the starter votes) | #652 |

## Follow-ups (not in this plan)

- Show a real name for persons created from an email address (the starter and invited contributors
  appear under their address until renamed).
- ~~Date picker instead of the native `datetime-local` input~~ — done with
  [vanilla-calendar-pro](https://github.com/uvarov-frontend/vanilla-calendar-pro) 3.4.0 (vendored,
  `RadiatorWeb.Components.DateTimePicker`, colocated hook) instead of Cally. The calendar's JS is
  loaded lazily via `import()` (esbuild `--splitting`, `app.js` as ES module); its CSS (scoped to
  `[data-vc…]`, ~6 KB gzipped) stays in `app.css`. Own overrides would go into ColocatedCSS.
- Realtime updates of the matrix for other viewers (PubSub).
- Notifications when a date is chosen or reopened.
- Reject or warn about proposals in the past.
- Optimistic locking if concurrent votes overwrite each other (ADR 0001 §2).
- Turn the committed dev migration `20261012184305_migrate_resources_extensions_1_dev.exs` into a real one.
- Upgrade `ash`, `ash_postgres`, `plug_crypto` (security advisories).

## Verification

- Per phase: `mix test <new test files>`; finally `mix precommit` (compile, format, credo, tests).
- `mix ash.codegen --check` shows no pending migrations after Phases 1–2.
- Manual: `mix ecto.reset && mix phx.server`; as member start a scheduling, add a contributor by email,
  follow the mail link from `/dev/mailbox` as that user, vote, then as member finalize → episode shows
  `:scheduled`, reopen → `:scheduling`, votes still present.
