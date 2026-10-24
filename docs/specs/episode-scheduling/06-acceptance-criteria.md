# 06 – Acceptance Criteria

Given/When/Then scenarios. Most are taken from the legacy test suite (source in brackets); scenarios
marked **(new)** cover intended behavior that legacy does not implement. Legacy test files:

- `[ES]` `test/radiator/episode_scheduling_test.exs`
- `[ST]` `test/radiator/podcasts/episode/scheduling_test.exs`
- `[WF]` `test/integration/scheduling_workflow_test.exs`
- `[PBA]` `test/radiator/podcasts/episode/scheduling/validations/persona_belongs_to_actor_test.exs`
- `[ET]` `test/radiator/episode_test.exs`
- `[SL]` / `[FL]` / `[AH]` `test/radiator_web/live/admin/episodes/{show_live,form_live,availability_helpers}_test.exs`

Common setup: podcast, episode, owner persona, participants with personas linked to users.

## A. Creating a scheduling

1. Given an episode, when the owner starts a scheduling with 3 datetimes and participants, then
   status is `:open`, `published_at` is set, there are 3 proposals each created by the owner with no votes. [ES]
2. When starting with an empty datetime list, then it fails on `proposed_datetimes`. [ES]
3. Given an episode with a scheduling, when another scheduling is created for it, then it fails
   (*episode already has a scheduling*).
4. When an episode is created with nested scheduling + proposals in one call, then episode,
   scheduling and proposals exist; `created_by_persona_id` is preserved per proposal. [ET, ST]
5. When an episode is created without scheduling params, then it has no scheduling. [ET]
6. Given an episode without scheduling, when it is updated with scheduling params, then a
   scheduling is created. [ET]
7. **(new)** When an episode with participants is saved with proposals via the form, then
   `participant_persona_ids` equals the episode's participant persona ids.
8. **(new)** Creating a scheduling with zero proposals via the form is rejected / not created.

## B. Voting

1. Given an open scheduling, when a participant votes 1 / 0 / -1, then the vote is stored with that score and `voted_at`. [ST, ES]
2. A vote may carry a comment, which is stored. [ES]
3. When a participant votes again on the same proposal with another score, then only the latest
   vote remains (replace semantics). [ST, ES, WF]
4. Scores 2, -2, 5 are rejected (*Score must be -1, 0 or 1*). Nil score is rejected. [ST, ES]
5. A non-participant cannot vote (*Only participants can vote*). [ES]
6. Voting on a closed scheduling fails (*Cannot vote on a closed scheduling*). [ES]
7. Voting with another participant's `persona_id` fails (*persona does not belong to current user*). [ST, PBA]
8. Persona-belongs-to-actor passes when `persona.user_id == actor.id`; fails for a different user,
   for a persona without user, without actor, and for a non-User actor. [PBA]
9. **(new)** Voting on an unknown `proposal_id` fails (*Proposal not found*).

## C. Proposals

1. A participant can add a proposal; it is stored with `created_by_persona_id` = that participant. [ES]
2. A non-participant cannot add a proposal. [ES]
3. Adding to a closed scheduling fails. [ES]
4. The owner can remove any proposal. [ES, WF]
5. The creator can remove their own proposal. [ES]
6. A participant cannot remove someone else's proposal. [ES]
7. Removing from a closed scheduling fails. [ES]
8. **(new)** Adding/removing with a persona not belonging to the actor fails.

## D. Removing votes

1. A participant can remove their own vote → that cell is pending again. [ES, WF]
2. Removing votes on a closed scheduling fails. [ES]
3. **(new)** A participant cannot remove another participant's vote.

## E. Finalize and reopen

1. The owner finalizes with an existing proposal → `:closed`, `chosen_proposal_id`,
   `chosen_datetime` = proposal datetime, `finalized_at` set. [ES, WF]
2. A non-owner cannot finalize. [ES]
3. Finalizing with a non-existent proposal fails (*Chosen proposal not found*). [ES]
4. Finalizing an already closed scheduling fails. [ES]
5. The owner can reopen a closed scheduling → `:open`, chosen fields and `finalized_at` cleared,
   votes kept. [ES, WF]
6. A non-owner cannot reopen. [ES]
7. After finalize, voting is rejected. [WF]
8. **(new)** Finalize moves the episode to `:scheduled`; reopen moves it back to `:scheduling`,
   atomically with the scheduling change.

## F. Statistics and ranking

1. `voting_stats` yields `total_score`, yes/maybe/no counts and `pending_count = 0` when everybody voted. [ST]
2. A proposal without votes has `pending_count == participant_count` and `total_score == 0`. [ST, ES]
3. `pending_count` counts only participants without a vote on that proposal; score 0 counts as maybe, never pending. [ST]
4. `proposal_stats` is sorted by `total_score` descending. [ST]
5. `top_proposal_id` is the unique max; `nil` on tie; `nil` without proposals;
   equals `voting_stats(...).top_proposal_id`. [ST]
6. **(new)** Ties are ordered by yes_count desc, then datetime asc.
7. **(new)** `all_voted?` is true only when no participant has a pending cell.
8. **(new)** Votes of removed participants are not counted.

## G. Episode states

1. A new episode starts in `:scheduling`. [ES]
2. `finalize_scheduling` → `:scheduled`; `back_to_scheduling` → `:scheduling`. [ES]

## H. Episode form UI

1. Not signed in → redirect to `/sign-in`. [FL]
2. User without persona clicks "Add Proposal" → flash error, no date input added. [FL]
3. User with persona sees title input, "Add Proposal" and "Add Participant". [FL]
4. "Add Proposal" adds one date/time input per click. [FL]
5. Saving with one proposal creates episode, scheduling (owner = current persona) and 1 proposal, then navigates to the show page. [FL]
6. Saving without proposals creates the episode without scheduling. [FL]
7. Remove (✕) removes the row. [FL]
8. Edit form shows existing proposals; can add and remove proposals. [FL]

## I. Availability matrix UI

As a participant with linked persona (open scheduling): [SL]

1. Availability section and table render inside a horizontally scrollable container.
2. Own row is marked "(you)"; other rows are not.
3. Weekday labels in headers; weekend headers highlighted.
4. Winner header and footer cell carry the winner border; trophy shown.
5. Other participants' votes render as success/warning/error icons; pending as faint "–".
6. Own row renders three buttons per proposal instead of icons.
7. Footer shows sign-prefixed scores.
8. Name column is sticky.
9. Clicking yes highlights yes and updates the footer; clicking no afterwards flips the highlight and the footer.
10. A manipulated score value shows the error flash and writes nothing.

Closed scheduling: [SL, AH]

11. All own buttons are disabled; a forced vote event writes nothing.
12. The chosen proposal shows the "Chosen" badge, and the winner highlight follows the chosen proposal, not the automatic top.
13. Closed without chosen proposal: no badge, no winner highlight.

Other viewers: [SL, AH]

14. User without persona: table renders, no "(you)", no vote buttons.
15. User with persona who is not a participant: same as 14.
16. `can_vote?` is false for nil persona, nil scheduling, non-participant, closed scheduling; true for a participant on open.

Owner controls **(new)**:

17. Only the owner sees ranking, "Choose this date" and "Reopen".
18. Choosing a date finalizes and the page shows the closed state.

## J. Seeds

1. After `mix ecto.reset`, user Bob has a linked persona that is a participant in the
   `future_episode` scheduling, with some example votes from other personas, so Bob can sign in and vote.
