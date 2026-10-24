# 03 – Ranking and Statistics

The ranking is the owner's decision aid. It is computed on read (pure function of the scheduling),
never stored.

Only votes of **current participants** are counted (votes of personas who are no longer in
`participant_persona_ids` are ignored).

## 1. Per-proposal statistics

| Field | Type | Definition |
| --- | --- | --- |
| `proposal_id` | uuid | |
| `datetime` | utc_datetime | |
| `total_score` | integer | Σ `score` of all votes (yes = +1, maybe = 0, no = −1) |
| `yes_count` | integer | votes with score `1` |
| `maybe_count` | integer | votes with score `0` |
| `no_count` | integer | votes with score `-1` |
| `pending_count` | integer | participants without a vote on this proposal (maybe ≠ pending) |
| `votes` | list | raw votes, for UI rendering |

Invariant: `yes_count + maybe_count + no_count + pending_count == participant_count`.

## 2. Aggregate statistics — `voting_stats(scheduling)`

| Field | Definition |
| --- | --- |
| `status` | scheduling status |
| `participant_count` | number of participants |
| `proposal_count` | number of proposals |
| `total_votes` | number of votes across all proposals |
| `voted_participant_count` | participants with at least one vote |
| `all_voted?` | every participant has voted on **every** proposal (no pending cell left) |
| `proposal_stats` | per-proposal stats in **ranking order** (§3) |
| `top_proposal` | first entry of `proposal_stats` (or `nil`) |
| `top_proposal_id` | see §4 |

## 3. Ranking order

Sort `proposal_stats` by:

1. `total_score` descending
2. `yes_count` descending (more definite yeses win)
3. `no_count` ascending (fewer people blocked)
4. `datetime` ascending (earlier slot first)

The ranking is therefore deterministic. (Legacy sorts by `total_score` only; tie order undefined.)

## 4. Top proposal

`top_proposal_id(scheduling)`:

- `nil` when there are no proposals
- `nil` when two or more proposals share the highest `total_score` (no unique winner — the
  tie-breakers of §3 only order the list, they do **not** create a top proposal)
- otherwise the id of the proposal with the highest `total_score`

`voting_stats(s).top_proposal_id == top_proposal_id(s)` always.

## 5. Winner (UI highlight)

```
winner_proposal_id(scheduling, top_proposal_id) =
  nil                              when scheduling is nil
  scheduling.chosen_proposal_id    when status == :closed   (may be nil)
  top_proposal_id                  when status == :open
```

When closed, the owner's explicit choice always beats the automatic ranking.

## 6. Worked example

Participants: Alice, Bob, Carol, Dave.

| | P1 Fri 19:00 | P2 Sat 10:00 | P3 Sun 19:00 |
| --- | :-: | :-: | :-: |
| Alice | yes | yes | no |
| Bob | yes | maybe | – |
| Carol | maybe | yes | yes |
| Dave | no | yes | – |
| **total_score** | **+1** | **+3** | **0** |
| yes / maybe / no / pending | 2 / 1 / 1 / 0 | 3 / 1 / 0 / 0 | 1 / 0 / 1 / 2 |

Ranking: P2, P1, P3. `top_proposal_id = P2`. `all_voted? = false` (P3 has pending cells).
`voted_participant_count = 4`.

If Dave's P1 vote changed from no to yes, P1 would also reach +3 (3 yes / 1 maybe):
`top_proposal_id = nil` (tie). Both have equal yes_count and no_count, so the ranking falls back
to datetime: P1 (Fri) before P2 (Sat).
