# Issue 02: Score-Modell auf -1/0/1 + neue Voting-Statistik

## Parent

[Epic: Episode Availability Voting](./00-epic.md)

## What to build

Das existierende Vote-Modell nutzt `score :integer` mit Wertebereich 1..5. Das Feature braucht aber genau drei diskrete Status: `-1 = nein`, `0 = vielleicht`, `+1 = ja`. Dieser Schnitt baut das Datenmodell und die abgeleitete Statistik um.

**Warum `:integer` statt `:atom`-Enum?** Top-Vorschlag-Berechnung wird zur simplen Summe pro Proposal — kein Mapping `:yes → 1` nötig. Auch in zukünftigen DB-Aggregationen (`SUM(score)`) bleibt das Modell direkt nutzbar.

**Wichtig**: „noch nicht abgestimmt" ist **kein** `score = 0`, sondern **kein Vote-Eintrag** für die Persona im `votes`-Array. `score = 0` bedeutet ausschließlich „vielleicht".

Demoable in iex: `Scheduling.voting_stats(scheduling)` liefert die neue Struktur mit `total_score`, `yes_count`, `no_count`, `maybe_count`, `pending_count` und `top_proposal_id`.

### Konkrete Änderungen

- **`Radiator.Podcasts.Episode.Scheduling.Vote`**:
  - `attribute :score, :integer`: `constraints one_of: [-1, 0, 1]`
  - Modulkopf-Doku komplett neu fassen (siehe Spec §3.2)
  - `comment :string` bleibt unverändert (Backend-Feld, in v1 nicht UI-exponiert)
- **`Radiator.Podcasts.Episode.Scheduling.Validations.ValidScore`**:
  - Wertebereich-Check auf `score in [-1, 0, 1]`
  - Fehlermeldung sinngemäß `"score must be -1, 0 or 1"`
- **`Radiator.Podcasts.Episode.Scheduling`**:
  - `voting_stats/1` umbauen: pro Proposal die Felder `proposal_id`, `datetime`, `total_score`, `yes_count`, `maybe_count`, `no_count`, `pending_count`, `votes`
  - Top-Level `top_proposal_id` als zusätzliches Feld (Vorschlag mit höchstem `total_score`; bei Gleichstand `nil`)
  - Sortierung der `proposal_stats`: nach `total_score desc`
  - Neue Helper-Funktion `top_proposal_id/1`
  - Alte `average_score`-basierte Logik in `voting_stats` entfernen
- **Seeds (`priv/repo/seeds.exs`)**:
  - Bestehende Vote-Calls: `score: 5` → `score: 1`, `score: 4` → `score: 1`, `score: 3` → `score: 0` (nichts mit `score: 2` oder `1` da, aber Konvention zur Vollständigkeit dokumentieren: `2`→`-1`, `1`→`-1`)

### Außerhalb dieses Schnitts

- Die neue `PersonaBelongsToActor`-Validation für die `:vote`-Action gehört zu Issue 04, nicht hier.
- `:vote`-Action-Logik (Replace-Semantik) bleibt unverändert; nur der Wertebereich des Arguments ändert sich implizit über `ValidScore`.

## Acceptance criteria

- [ ] `Vote.score` akzeptiert nur Werte aus `[-1, 0, 1]`; alle anderen Werte werden mit klarer Fehlermeldung abgelehnt (Test)
- [ ] `Scheduling.vote(s, p, persona, 2)` schlägt fehl mit `ValidScore`-Fehler (Test)
- [ ] `Scheduling.vote(s, p, persona, 1)` legt Vote-Eintrag mit `score: 1` an (Test)
- [ ] `Scheduling.vote(s, p, persona, 0)` legt Vote-Eintrag mit `score: 0` an (Test)
- [ ] `Scheduling.vote(s, p, persona, -1)` legt Vote-Eintrag mit `score: -1` an (Test)
- [ ] `Scheduling.vote` zweimal hintereinander mit unterschiedlichen Scores für dieselbe Persona: nur die letzte Stimme bleibt (Test der Replace-Semantik)
- [ ] `Scheduling.voting_stats(scheduling)` liefert pro Proposal `total_score`, `yes_count`, `maybe_count`, `no_count`, `pending_count`, `votes`
- [ ] `pending_count` zählt Participants, die für diesen Proposal keinen Vote-Eintrag haben (Tests mit 0 Stimmen, mit gemischten Stimmen)
- [ ] Top-Level der `voting_stats`-Rückgabe enthält `top_proposal_id` (oder `top_proposal` mit ID); bei eindeutigem Sieger korrekt, bei Gleichstand `nil`
- [ ] Helper `Scheduling.top_proposal_id/1` ist öffentlich nutzbar und konsistent zu `voting_stats`
- [ ] Tests in `test/radiator/podcasts/episode/scheduling_test.exs` (neue Datei) decken alle obigen Fälle ab
- [ ] Seeds laufen fehlerfrei mit neuen Score-Werten
- [ ] `mix precommit` ist grün

## Blocked by

None - can start immediately (unabhängig von Issue 01)
