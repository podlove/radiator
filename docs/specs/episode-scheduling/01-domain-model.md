# 01 – Domain Model

```
Podcast 1──n Episode 1──0..1 Scheduling 1──n Proposal 1──n Vote
                │                 │                │          │
                n                 │ owner          │ creator  │ voter
          EpisodeParticipant      ▼                ▼          ▼
                n──1 Persona ◄────┴────────────────┴──────────┘
                        │ 0..1
                        ▼
                       User
```

## 1. Scheduling

One scheduling per episode. Legacy: Ash resource `Radiator.Podcasts.Episode.Scheduling`,
table `episode_scheduling`.

| Attribute | Type | Null | Default | Notes |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | generated | primary key |
| `episode_id` | uuid | no | – | FK `episodes.id`, **ON DELETE CASCADE**, **unique** (`"episode already has a scheduling"`) |
| `owner_persona_id` | uuid | no | – | FK `personas.id`, **ON DELETE RESTRICT** (a persona owning a scheduling cannot be deleted); indexed |
| `status` | enum `:open` \| `:closed` | no | `:open` | |
| `participant_persona_ids` | uuid[] | no | `[]` | personas allowed to vote |
| `proposals` | list of Proposal | no | `[]` | see §2 |
| `chosen_proposal_id` | uuid | yes | – | set on finalize, cleared on reopen |
| `chosen_datetime` | utc_datetime | yes | – | copy of the chosen proposal's datetime (denormalized for easy querying) |
| `published_at` | utc_datetime | yes | – | when the poll became available for voting (= creation time) |
| `finalized_at` | utc_datetime | yes | – | set on finalize, cleared on reopen |
| `inserted_at`, `updated_at` | utc_datetime_usec | no | now | |

Derived:

- `chosen_proposal` — the proposal struct whose `id == chosen_proposal_id`, or `nil`.

Invariants:

- `status == :closed` ⇔ `chosen_proposal_id` and `chosen_datetime` and `finalized_at` are set.
- `chosen_proposal_id`, if set, references a proposal of this scheduling.
- `chosen_datetime == chosen_proposal.datetime`.

## 2. Proposal

A candidate date/time. Legacy: embedded resource `…Scheduling.Proposal`, stored as a JSONB
array inside the scheduling row.

| Attribute | Type | Null | Default | Notes |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | generated | stable id, referenced by votes and `chosen_proposal_id` |
| `datetime` | utc_datetime | no | – | the proposed start of the recording, stored in UTC |
| `created_by_persona_id` | uuid | no | – | who proposed it (owner or a participant) |
| `votes` | list of Vote | no | `[]` | see §3 |
| `inserted_at`, `updated_at` | utc_datetime | yes | now (truncated to seconds) | |

Helpers expected on a proposal: `vote_by_persona(proposal, persona_id)`,
`voted?(proposal, persona_id)`, `votes_count(proposal)`.

## 3. Vote

| Attribute | Type | Null | Default | Notes |
| --- | --- | --- | --- | --- |
| `persona_id` | uuid | no | – | the voter |
| `score` | integer | no | – | **exactly one of `-1`, `0`, `1`** |
| `voted_at` | utc_datetime | no | now | updated whenever the vote is replaced |
| `comment` | string | yes | – | free text; stored, not exposed in the v1 UI |

Score semantics:

| Score | Label | Meaning |
| ---: | --- | --- |
| `1` | yes | can attend |
| `0` | maybe | unsure / tentative |
| `-1` | no | cannot attend |
| *(no vote)* | pending | has not answered — **not** counted as 0 |

Invariant: **at most one vote per persona per proposal.**

## 4. Persona ↔ User link

Needed to answer "which persona is the signed-in user?".

- `personas.user_id` — nullable FK to `users.id`, **ON DELETE SET NULL**.
- Unique index on `user_id` → a user has at most one persona (v1).
- A persona without a user is valid (e.g. external guests); such personas can be participants
  but cannot vote themselves.
- Lookup: `Persona.get_by_user(user_id)` → `{:ok, persona}` | `{:error, not_found}`.

## 5. Relation to episode participants

An episode has `participants` (many-to-many personas via `EpisodeParticipant`, unique per
episode/persona). The scheduling has its own `participant_persona_ids`.

**Intended rule:** the scheduling participants are the episode participants. When the scheduling
is created through the episode form, and whenever episode participants change while the scheduling
is open, `participant_persona_ids` is synchronized with the episode's participant persona ids.
Votes of personas that are removed as participants stay stored but are ignored by statistics
(see [03](./03-ranking-and-stats.md)). See gap #1 in [07](./07-known-gaps-and-decisions.md).

## 6. Persistence choice

Legacy stores proposals and votes embedded (JSONB array) in the scheduling row. This keeps the
whole poll atomic and simple, at the cost of read-modify-write updates (`require_atomic? false`)
and possible lost updates on concurrent votes. The reimplementation may keep embedding or use
separate `scheduling_proposals` / `scheduling_votes` tables (with a unique index on
`(proposal_id, persona_id)`); the behavior in this spec is the same either way.
