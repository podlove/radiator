# 07 – Known Gaps in the Legacy Implementation and Decisions

Each item: **Legacy** = what the branch `feature/create-with-participants` does;
**Intended** = what this spec requires (or the open question to decide).

## 1. Scheduling participants are not filled from the episode form

- **Legacy**: `create_with_proposals` (used by the episode form) does not set
  `participant_persona_ids`; it stays `[]`, so nobody can vote on a scheduling created through the UI.
  The matrix rows are the scheduling participants, so the matrix is empty.
- **Intended**: scheduling participants = episode participants, synchronized on save
  ([01 §5](./01-domain-model.md#5-relation-to-episode-participants)).
- **Decision needed**: keep `participant_persona_ids` as a separate list (allows non-voting episode
  participants) or derive it from `episode.participants` entirely (recommended: derive, simpler).

## 2. Actor check only on `vote`

- **Legacy**: only `vote` uses `PersonaBelongsToActor`. `add_proposal`, `remove_proposal`,
  `remove_vote`, `finalize`, `reopen` trust the `persona_id` argument → anyone can act as the
  owner by passing the owner's persona id. No Ash policies on the resource.
- **Intended**: all mutating actions check the actor ([04](./04-authorization.md)); preferably via
  Ash policies, deriving the persona from the actor instead of taking it as an argument.

## 3. Episode state not coupled to scheduling

- **Legacy**: `Scheduling.finalize` and `Episode.finalize_scheduling` are separate calls;
  states can diverge. The `:creation` state is unreachable because the initial state is `:scheduling`.
  `finalize_scheduling` writes the recording datetime into `publication_date`.
- **Intended**: finalize/reopen transition the episode in the same transaction
  ([02 §9](./02-actions-and-rules.md#9-coupling-with-the-episode-state-machine)).
- **Decision needed**: remove `:creation` or make it the initial state; dedicated `recording_at`
  instead of misusing `publication_date` (recommended).

## 4. Time zones and localization

- **Legacy**: the form uses `datetime-local` (naive) and stores it as UTC without conversion;
  the matrix renders UTC. Weekday labels are hard-coded German, "(du)" is German inside gettext.
- **Intended**: convert from the user's (or podcast's) time zone on input, render in the viewer's
  time zone; localized weekday names via gettext/Cldr; "(you)" as msgid.

## 5. Ranking ties

- **Legacy**: sort by `total_score` only; order among equal scores is undefined.
- **Intended**: deterministic tie-breakers ([03 §3](./03-ranking-and-stats.md#3-ranking-order)).

## 6. `all_voted?` semantics

- **Legacy**: true when the number of distinct personas with at least one vote equals the
  participant count (also counts votes of non-participants).
- **Intended**: true only when every participant voted on every proposal.

## 7. Weak input validation

- **Legacy**: `create_with_proposals` accepts zero proposals; duplicate and past datetimes are
  accepted; `vote`/`remove_vote` with an unknown `proposal_id` silently succeed; `participant_persona_ids`
  are not validated to exist.
- **Intended**: ≥1 proposal; reject duplicates; warn (or reject) on past dates (decision);
  *Proposal not found* on unknown ids; participant ids must reference personas.

## 8. Duplicated / dead code

- **Legacy**: vote logic exists twice (`Proposal.add_vote/remove_vote` and `Scheduling.vote/remove_vote`);
  `Proposal.average_score` and `total_votes` calculations are unused; `Scheduling.create` builds
  proposals as maps while `create_with_proposals` receives them from the form.
- **Intended**: one code path per operation.

## 9. Owner is not automatically a participant

- **Legacy**: the owner can vote, add proposals or remove votes only when explicitly listed in
  `participant_persona_ids` (`add_proposal` is participant-only).
- **Decision needed**: add the owner automatically (recommended), or leave it to the episode participants list.

## 10. Freshness and concurrency

- **Legacy**: after each vote the whole episode is re-read; other viewers don't see updates;
  embedded JSONB + read-modify-write means two simultaneous votes can overwrite each other.
- **Intended**: acceptable for v1; if keeping embedded storage, use optimistic locking or
  re-read-and-apply inside a transaction. PubSub realtime is a follow-up.

## 11. Votes of removed participants

- **Legacy**: statistics count every stored vote, including those of personas no longer participating.
- **Intended**: ignore them in statistics ([03](./03-ranking-and-stats.md)); keep them stored so
  re-adding the participant restores the vote.

## 12. Owner UI missing

- **Legacy**: no UI for finalize, reopen, ranking, add/remove proposal on the show page, remove vote,
  comments. Only possible via iex/seeds.
- **Intended**: owner controls per [05 §2.3](./05-ui.md#23-owner-controls-intended-not-present-in-the-legacy-ui).

## 13. Outdated documentation

- **Legacy**: `SCHEDULING_README.md` / `SCHEDULING_IMPLEMENTATION_SUMMARY.md` describe a 1–5 score
  scale and `average_score`; `docs/specs/episode-availability-voting*.md` cover only the UI.
- **Intended**: this directory is the single source of truth; the old files should not be carried over.

## 14. Backlog notes from the legacy `todo` file

- Seeds: add participants
- Adding a proposal should take effect immediately (without saving the whole form)
- Date picker: DaisyUI + Cally (<https://github.com/WickyNilliams/cally>)
- Use colocated hooks for JS
