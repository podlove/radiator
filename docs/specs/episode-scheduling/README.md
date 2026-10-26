# Episode Scheduling & Availability Voting — Specification

- **Status**: Specification for reimplementation on the main branch
- **Source**: legacy branch `feature/create-with-participants` (last commit `96c27677`)
- **Supersedes**: `SCHEDULING_README.md`, `SCHEDULING_IMPLEMENTATION_SUMMARY.md` (both describe an
  outdated 1–5 score model) and `docs/specs/episode-availability-voting*.md` (UI-only, German)

> **Terminology on main:** the spec was written against the legacy model. On `main`, *persona* is
> `Radiator.Podcasts.Person` (logged-in user = `person.account_id`), *participant* is an episode
> *contributor* with an account, and *owner* is any podcast member. See the
> [implementation plan](../../plans/episode-scheduling.md) and
> [ADR 0001](../../adrs/0001-episode-scheduling.md).

This spec describes the **intended** behavior. Where the legacy code differs, the deviation is
listed in [07 – Known gaps and decisions](./07-known-gaps-and-decisions.md). It is deliberately
implementation-agnostic where possible; the legacy implementation (Ash + AshPostgres + LiveView)
is mentioned as a reference, not as a requirement.

## 1. Purpose

Every new episode starts with **scheduling**: finding the best date and time for the recording
session. The episode owner (and participants) propose date/time slots, every participant marks
their availability per slot (yes / maybe / no), and the owner gets a **ranking** of the slots.
The owner makes the final decision — the ranking is advisory, not binding.

It works like a Doodle poll embedded in the episode admin pages.

## 2. Glossary

| Term | Meaning |
| --- | --- |
| **User** | A signed-in account (`Radiator.Accounts.User`). |
| **Persona** | A public identity (name, handle, avatar). Participants of episodes are personas. A user is linked to at most one persona. |
| **Episode participant** | A persona attached to an episode (join resource `EpisodeParticipant`). |
| **Scheduling** | The poll of one episode. Exactly zero or one per episode. |
| **Owner** | The persona that created the scheduling. Only the owner may finalize / reopen. |
| **Participant** | A persona allowed to vote in a scheduling (`participant_persona_ids`). |
| **Proposal** | One candidate date/time slot inside a scheduling. |
| **Vote** | A participant's availability for one proposal: score `1` (yes), `0` (maybe), `-1` (no). |
| **Pending** | A participant has not voted on a proposal yet. Pending is *not* a score of 0. |
| **Total score** | Sum of all vote scores of a proposal. |
| **Ranking** | Proposals ordered by total score (best first). |
| **Top proposal** | The unique proposal with the highest total score (none on a tie). |
| **Chosen proposal** | The proposal the owner picked when finalizing. |
| **Winner** | The proposal highlighted in the UI: the chosen one when closed, the top proposal while open. |

## 3. Lifecycle

### 3.1 Episode states

```
            begin_scheduling                finalize_scheduling
 :creation ─────────────────► :scheduling ─────────────────────► :scheduled
                                   ▲                                  │
                                   └──────── back_to_scheduling ──────┘
```

A newly created episode starts in `:scheduling` (default initial state).

### 3.2 Scheduling status

```
          finalize(chosen proposal)
  :open ─────────────────────────────► :closed
    ▲                                     │
    └──────────────── reopen ─────────────┘
```

- `:open` — proposals can be added/removed, participants can vote.
- `:closed` — read-only; a proposal has been chosen and its datetime is fixed.

Finalizing the scheduling moves the episode to `:scheduled`; reopening moves it back to
`:scheduling` (see [02](./02-actions-and-rules.md#9-coupling-with-the-episode-state-machine)).

### 3.3 Typical flow

1. Owner creates (or edits) an episode, adds participants and one or more proposed date/times.
2. The scheduling is created in status `:open`; `published_at` is set.
3. Participants open the episode page and mark yes / maybe / no for each proposal.
4. Participants may add further proposals; the owner or the proposal's creator may remove one.
5. The owner watches the ranking and picks a proposal → scheduling `:closed`, episode `:scheduled`.
6. If the date no longer works, the owner reopens the scheduling; existing votes are kept.

## 4. Scope

### In scope (v1)

- Data model for scheduling, proposals and votes
- User ↔ persona link (needed to know "who am I" when voting)
- Creating proposals as part of the episode create/edit form
- Availability matrix with voting on the episode show page
- Ranking / statistics and winner highlight
- Finalize and reopen (domain actions + owner controls in the UI)
- Authorization: everybody signed in can see, only participants vote, only the owner decides

### Out of scope (v1)

- Notifications (e-mail / in-app) to participants or owner
- Realtime updates of other viewers (PubSub)
- Comments on votes in the UI (the field exists in the model)
- Multiple personas per user
- Voting deadlines, time zone per participant, calendar export (iCal)
- Public (not signed-in) voting links for external guests

## 5. Documents

| File | Content |
| --- | --- |
| [01-domain-model.md](./01-domain-model.md) | Entities, attributes, constraints, persistence |
| [02-actions-and-rules.md](./02-actions-and-rules.md) | Every action with inputs, preconditions, effects, errors |
| [03-ranking-and-stats.md](./03-ranking-and-stats.md) | Statistics, ranking, top proposal, winner rule |
| [04-authorization.md](./04-authorization.md) | Who may do what |
| [05-ui.md](./05-ui.md) | Episode form and availability matrix |
| [06-acceptance-criteria.md](./06-acceptance-criteria.md) | Given/When/Then scenarios for tests |
| [07-known-gaps-and-decisions.md](./07-known-gaps-and-decisions.md) | Legacy deviations and open questions |
| [08-mainline-mapping.md](./08-mainline-mapping.md) | How the spec maps to the implementation on `main` |
