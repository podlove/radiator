---
name: remove-persona-refactor
description: Domain-Cleanup-Vorhaben, das die Persona-Resource entfernt; User wird Akteur, Person wird referenzierbar
metadata:
  type: project
---

Laufendes Aufräum-Vorhaben (Stand 2026-06-21): Die Resource `Radiator.People.Persona` und die Tabelle `personas` werden komplett entfernt. Detaillierter Plan: `docs/superpowers/plans/2026-06-21-remove-persona.md`.

Beschlossenes Zielmodell:
- **User** (`Accounts`) = pseudonymer Account + Akteur im Scheduling: `email`, `hashed_password` (wird OPTIONAL via magic_link), `handle` (unique), `avatar_url`, `person_id` (FK, optional, 1:1). Kein `public_name`/`description`.
- **Person** (`People`) = realer, eigenständig referenzierbarer Mensch (z. B. Harald Lesch): `first_name`, `last_name`, `display_name`, `homepage_url`, `wikipedia_url`, `bio`. `has_one :user`.
- Alle `*persona*`-Referenzen im Scheduling/Episode-Modell → `*user*` (`owner_user_id`, `participant_user_ids`, `Proposal.created_by_user_id`, `Vote.user_id`, `EpisodeParticipant.user`).
- **Teilnehmer-Flow:** Beim Episode-Speichern unbekannte Teilnehmer-E-Mails als passwortlose User anlegen (`:invite_by_email` via `manage_relationship`), danach Magic-Link-Mail („hier kannst du abstimmen") → loggt genau diesen User ein und leitet per `return_to` direkt zur Abstimmungsseite der Episode.

**Why:** Persona vermischte öffentliches Profil und Akteur-Rolle; war ein halbfertiges Feature. User+Person reichen aus.

**How to apply:** Beim Weiterarbeiten dem Plan folgen; bei Domain-Änderungen Skill `ash-framework`, bei Web/Auth-Routing Skill `phoenix-framework`. Magic-Link wurde via `mix ash_authentication.add_strategy magic_link` eingeführt — generierte Action-/Routennamen sind die Quelle der Wahrheit.
