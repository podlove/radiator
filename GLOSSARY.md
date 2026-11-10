# Radiator

Radiator is a podcast publishing platform. Members manage podcasts and their episodes; before recording, an episode's date is found through a scheduling.

## Podcasts and people

**Member**:
A user who holds a role on a podcast. `owner` is one such role, not a separate kind of person.
_Avoid_: Owner (for a person), admin

**Contributor**:
A person credited on an episode, with or without an account of their own.
_Avoid_: Persona

## Episode scheduling

**Scheduling**:
The search for an episode's recording date, Doodle-style: Proposals are voted on and the Organizer finalizes one.
_Avoid_: Poll, Doodle

**Organizer**:
The Member who started a Scheduling or took it over. Only the Organizer finalizes and reopens, and only while still a Member.
_Avoid_: Owner, creator, starter

**Participant**:
A Contributor of the episode who has their own account and therefore votes in its Scheduling.
_Avoid_: Voter, persona

**Proposal**:
A proposed date and time for the recording.
_Avoid_: Slot, option, date

**Vote**:
One Participant's yes, maybe or no on one Proposal.
_Avoid_: Answer, score

**Ranking**:
All Proposals of a Scheduling, ordered by their Votes.

**Best proposal**:
The Proposal ranked highest by Votes. Advisory only; the Organizer may choose another.
_Avoid_: Winner, top proposal

**Chosen proposal**:
The Proposal the Organizer picked when finalizing.
_Avoid_: Winner, picked date

**Finalize**:
The Organizer closes the Scheduling by choosing the Chosen proposal; the episode becomes scheduled.
_Avoid_: Pick, decide, close

**Reopen**:
The Organizer undoes a Finalize; Proposals and Votes are kept.

**Take over**:
A Member becomes the Organizer of a Scheduling whose Organizer is gone (no longer a Member, or account deleted).
