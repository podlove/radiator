# 04 – Authorization

## 1. Principles

- All scheduling pages are behind the admin login wall; anonymous visitors are redirected to `/sign-in`.
- Votes are **not anonymous**: every signed-in user who can see the episode sees everybody's votes.
- A user acts through their linked persona (`Persona.get_by_user/1`). A user without a persona can
  look but not act.
- Every mutating action checks that the `persona_id` argument **belongs to the actor**
  (`persona.user_id == actor.id`). Otherwise a user could act as somebody else simply by passing
  another persona id. In the reimplementation this should be an Ash policy (or a shared
  validation) applied to all scheduling update actions, not only `vote`.
- Role checks (participant / owner / creator) are made against the scheduling record.

## 2. Matrix

✓ = allowed, – = denied. "Open"/"Closed" refer to scheduling status.

| Actor | View matrix | Vote / change vote | Remove own vote | Add proposal | Remove proposal | Finalize | Reopen |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| Not signed in | – (login) | – | – | – | – | – | – |
| Signed in, no persona | ✓ | – | – | – | – | – | – |
| Persona, not participant | ✓ | – | – | – | – | – | – |
| Participant (open) | ✓ | ✓ own | ✓ | ✓ | ✓ own proposals | – | – |
| Owner (open) | ✓ | ✓ if participant | ✓ if participant | ✓ | ✓ any | ✓ | – |
| Owner (closed) | ✓ | – | – | – | – | – | ✓ |
| Anyone (closed) | ✓ | – | – | – | – | – | – |

Notes:

- The owner is a participant only if listed in `participant_persona_ids` (intended: the owner is
  normally an episode participant and thus included — see [07](./07-known-gaps-and-decisions.md) #9).
- Editing the episode (form) is open to any signed-in admin user in v1; adding proposals via the
  form requires the user to have a persona.

## 3. UI gating (`can_vote?`)

The vote buttons are enabled only if all hold:

- scheduling exists
- current persona exists
- `scheduling.status == :open`
- current persona is in `participant_persona_ids`

The UI gate is a convenience only; the server-side action validations are authoritative
(a manipulated client event must not change data).
