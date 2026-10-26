# 02 – Actions and Business Rules

All mutating actions take the **acting persona** (`persona_id`) and are executed with the
signed-in **user as actor**. Every mutating action must verify that `persona_id` belongs to the
actor ("persona belongs to actor", see [04](./04-authorization.md)). Error messages below are the
legacy wording and may be kept verbatim.

Validation order inside an action: cheap in-memory checks first, database lookups last:

1. scheduling status
2. argument shape (score whitelist, proposal exists)
3. role checks (participant / owner / proposal creator) — in-memory
4. persona belongs to actor — DB lookup

Errors are returned as `{:error, reason}`; nothing is persisted when any validation fails.

## 1. Start scheduling (`create`)

Creates a scheduling from a list of datetimes (API / seeds use case).

| | |
| --- | --- |
| Inputs | `episode_id`, `owner_persona_id`, `participant_persona_ids`, `proposed_datetimes :: [utc_datetime]` |
| Preconditions | episode has no scheduling yet; `proposed_datetimes` non-empty; actor owns `owner_persona_id` |
| Effect | one proposal per datetime, each with a new id, `created_by_persona_id = owner`, `votes = []`; `status = :open`; `published_at = now` |
| Errors | `"At least one proposed datetime is required"` (field `proposed_datetimes`); `"episode already has a scheduling"` |

Domain interface (legacy): `Radiator.Podcasts.start_scheduling/1`.

## 2. Create / update via the episode form (`create_with_proposals`, `update`)

The episode `create` and `update` actions accept a nested `scheduling` map (with nested
`proposals`) and manage the has-one relationship:

- no scheduling yet + scheduling params given → create scheduling (`status :open`, `published_at = now`)
  with the given proposals (each carries `datetime` and `created_by_persona_id`)
- scheduling exists + params given → replace the proposal list (proposals not in the params are
  removed, new ones added, existing ones updated by id; existing votes on kept proposals are preserved)
- no scheduling params at all → no scheduling is created

Intended rules (see [07](./07-known-gaps-and-decisions.md)):

- at least one proposal is required to create a scheduling (the form simply creates none when the
  user added no proposal row)
- `owner_persona_id` = the current user's persona
- `participant_persona_ids` = the episode's participant persona ids (synchronized)
- editing proposals via the form is only allowed while `status == :open`

## 3. Add proposal (`add_proposal`)

| | |
| --- | --- |
| Inputs | `datetime`, `persona_id` |
| Preconditions | `status == :open`; `persona_id` is a participant **or the owner**; persona belongs to actor |
| Effect | new proposal (`id` generated, `created_by_persona_id = persona_id`, `votes = []`) is added |
| Errors | `"Cannot add proposals to a closed scheduling"`; `"Only participants can add proposals"` |

Recommended (not in legacy): reject a datetime that duplicates an existing proposal.

## 4. Remove proposal (`remove_proposal`)

| | |
| --- | --- |
| Inputs | `proposal_id`, `persona_id` |
| Preconditions | `status == :open`; proposal exists; `persona_id` is the owner **or** the proposal's creator; persona belongs to actor |
| Effect | proposal and all its votes are removed |
| Errors | `"Cannot remove proposals from a closed scheduling"`; `"Proposal not found"`; `"Only the owner or proposal creator can remove proposals"` |

## 5. Vote (`vote`)

| | |
| --- | --- |
| Inputs | `proposal_id`, `persona_id`, `score ∈ {-1, 0, 1}`, optional `comment` |
| Preconditions (in this order) | `status == :open`; score valid; `persona_id` is a participant; persona belongs to actor; proposal exists |
| Effect | **replace semantics**: any previous vote of `persona_id` on that proposal is removed and a new vote `{persona_id, score, comment, voted_at: now}` is stored. Votes on other proposals are untouched. Voting the same score again is allowed (idempotent apart from `voted_at`). |
| Errors | `"Cannot vote on a closed scheduling"`; `"Score must be -1, 0 or 1"` (field `score`); `"Only participants can vote"`; `"persona does not belong to current user"` (field `persona_id`); missing/nil score → required-argument error |

"Persona belongs to actor" fails when: no actor; actor is not a `User`; persona doesn't exist;
persona has no `user_id`; `persona.user_id != actor.id`.

Recommended (not in legacy): fail with `"Proposal not found"` for an unknown `proposal_id`
(legacy silently succeeds without change).

## 6. Remove vote (`remove_vote`)

| | |
| --- | --- |
| Inputs | `proposal_id`, `persona_id` |
| Preconditions | `status == :open`; `persona_id` is a participant; persona belongs to actor |
| Effect | the vote of `persona_id` on that proposal is removed → participant is *pending* again |
| Errors | `"Cannot modify votes on a closed scheduling"`; `"Only participants can remove votes"` |

A participant can only remove **their own** vote (enforced by the actor check).

## 7. Finalize (`finalize`)

| | |
| --- | --- |
| Inputs | `chosen_proposal_id`, `persona_id` |
| Preconditions | `status == :open`; `persona_id == owner_persona_id`; persona belongs to actor; proposal exists |
| Effect | `status = :closed`; `chosen_proposal_id`; `chosen_datetime = proposal.datetime`; `finalized_at = now`; **episode transitions to `:scheduled`** (see §9) |
| Errors | `"Scheduling is already closed"`; `"Only the owner can finalize the scheduling"`; `"Chosen proposal not found"` |

The owner may choose **any** proposal, not necessarily the top-ranked one.

## 8. Reopen (`reopen`)

| | |
| --- | --- |
| Inputs | `persona_id` |
| Preconditions | `status == :closed`; `persona_id == owner_persona_id`; persona belongs to actor |
| Effect | `status = :open`; `chosen_proposal_id`, `chosen_datetime`, `finalized_at` cleared; **all proposals and votes are kept**; **episode transitions back to `:scheduling`** |
| Errors | `"Scheduling must be closed to reopen"`; `"Only the owner can reopen the scheduling"` |

## 9. Coupling with the episode state machine

Episode transitions (AshStateMachine in legacy):

| Action | From | To | Notes |
| --- | --- | --- | --- |
| `begin_scheduling` | `:creation` | `:scheduling` | |
| `finalize_scheduling` | `:scheduling` | `:scheduled` | accepts the chosen datetime (legacy writes it to `publication_date`) |
| `back_to_scheduling` | `:scheduled` | `:scheduling` | |

Intended: `finalize` and `reopen` on the scheduling perform the matching episode transition in the
**same transaction**, so scheduling status and episode state can never diverge
(`:closed` ⇔ `:scheduled`). In legacy these are two separate calls.

Open question: legacy stores the recording datetime in `publication_date`. Recording date and
publication date are different concepts; the reimplementation should decide whether to add a
dedicated `recording_at` attribute (recommended) or keep `chosen_datetime` on the scheduling as
the single source.

## 10. Reads and helpers

| Function | Returns |
| --- | --- |
| `get_by_episode(episode_id)` | the scheduling of an episode |
| `get_proposal(scheduling, proposal_id)` | proposal or `nil` |
| `voted_on_proposal?(scheduling, proposal_id, persona_id)` | boolean |
| `get_persona_votes(scheduling, persona_id)` | `[{proposal_id, vote}]` |
| `voting_stats(scheduling)` | see [03](./03-ranking-and-stats.md) |
| `top_proposal_id(scheduling)` | see [03](./03-ranking-and-stats.md) |
