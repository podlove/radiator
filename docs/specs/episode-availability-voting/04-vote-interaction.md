# Issue 04: Eigene Stimme abgeben (Voting-Interaktion)

## Parent

[Epic: Episode Availability Voting](./00-epic.md)

## What to build

Die in Issue 03 gebaute Tabelle wird interaktiv: In der eigenen Zeile bekommt jede Vote-Zelle **drei Buttons** (Yes / Maybe / No). Klick setzt den eigenen Status für den jeweiligen Vorschlag und re-rendert die Tabelle mit aktualisierten Aggregaten.

Server-seitig wird die `:vote`-Action durch eine **Actor-basierte Auth-Validation** abgesichert, damit Bob nicht als Jim abstimmen kann, indem er Jims `persona_id` mitschickt.

Demoable: Bob klickt auf einen Yes-Button, sieht ihn sofort als aktiv markiert, der Footer-Score springt um +1. Klick auf No überschreibt den vorherigen Vote (Replace-Semantik).

### Konkrete Änderungen

- **Neue Validation `Radiator.Podcasts.Episode.Scheduling.Validations.PersonaBelongsToActor`**:
  - Liest `actor` aus `context` und `persona_id` aus dem Argument
  - Lädt die Persona per `Persona |> Ash.Query.filter(id == ^persona_id and user_id == ^actor.id)` und erwartet genau ein Treffer
  - Schlägt fehl, wenn `actor` nicht zur angegebenen Persona gehört (z. B. wenn `persona.user_id != actor.id` oder `persona.user_id == nil`)
  - Fehlermeldung sinngemäß `"persona does not belong to current user"`
- **`:vote`-Action in `Radiator.Podcasts.Episode.Scheduling`**:
  - Validation-Reihenfolge (von billig nach teuer):
    1. `attribute_equals(:status, :open)` (bereits vorhanden)
    2. `ValidScore` (bereits vorhanden, aus Issue 02 ggf. mit neuem Wertebereich)
    3. `ParticipantOnly` (bereits vorhanden)
    4. `PersonaBelongsToActor` (neu, DB-Lookup, daher zuletzt)
- **`RadiatorWeb.Admin.Episodes.ShowLive`**:
  - In der eigenen Zeile (`current_persona` ist Participant) werden statt Status-Icons drei `<button>`s gerendert:
    - DOM-IDs: `vote-<proposal_id>-yes` / `-maybe` / `-no`
    - `phx-click="vote"`, `phx-value-proposal-id={proposal.id}`, `phx-value-score="1"|"0"|"-1"`
    - Aktiver Button (Status entspricht dem aktuellen Vote der Persona) bekommt Highlight-Klasse (z. B. `btn-success` / `btn-warning` / `btn-error`); inaktive `btn-ghost`
  - `handle_event("vote", %{"proposal-id" => pid, "score" => score_str}, socket)`:
    - Score-Whitelist: nur `"-1" | "0" | "1"` akzeptieren; sonst kein DB-Call
    - `Scheduling.vote(scheduling, pid, current_persona.id, score, actor: current_user)`
    - Bei `{:ok, _}` → Episode neu laden (mit denselben Loads); Tabelle re-rendert mit neuen Aggregaten
    - Bei `{:error, _}` → Flash mit `gettext("Could not record your vote.")`
  - Kein expliziter „unvote"-Button. Idempotenter Klick (gleicher Status nochmal) ist No-Op (durch Replace-Semantik der Action garantiert)

### Außerhalb dieses Schnitts

- Kein Disabled-State bei `:closed`, kein „Gewählt"-Badge (kommt in Issue 05)
- Kein Realtime via PubSub (siehe Spec §6 Out of Scope)
- Kein Kommentar-Feld, kein eigener Datumsvorschlag

## Acceptance criteria

- [ ] Neue Validation `PersonaBelongsToActor` existiert mit Modul-Doku und ist über `use Ash.Resource.Validation` korrekt registriert
- [ ] Validation-Tests in `test/radiator/podcasts/episode/scheduling/validations/persona_belongs_to_actor_test.exs`:
  - Passt: `persona.user_id == actor.id`
  - Schlägt fehl: `persona.user_id != actor.id` (Bob versucht Jims Persona zu nutzen)
  - Schlägt fehl: `persona.user_id == nil` (Persona ohne User-Verknüpfung)
- [ ] `:vote`-Action enthält die vier Validations in der spezifizierten Reihenfolge; `PersonaBelongsToActor` als letzter Eintrag
- [ ] Resource-Test in `test/radiator/podcasts/episode/scheduling_test.exs`: `vote` mit fremder `persona_id` schlägt mit `PersonaBelongsToActor`-Fehler fehl (Erweiterung gegenüber Issue 02)
- [ ] In Bobs Zeile rendert die LiveView pro Spalte drei Buttons mit den DOM-IDs `vote-<id>-yes` / `-maybe` / `-no`
- [ ] Bei Klick auf `vote-<id>-yes` wird der Button optisch aktiv; Footer-Score erhöht sich um 1; Bobs Zellinhalte in anderen Spalten bleiben unverändert
- [ ] Klick auf `vote-<id>-no` nach `vote-<id>-yes`: Yes-Button wird inaktiv, No-Button aktiv; Footer-Score sinkt entsprechend (Replace-Semantik durch UI bestätigt)
- [ ] Score-Whitelist im `handle_event`: ein manipulierter Wert (z. B. `"2"`) führt zu keinem DB-Call und zu einem Flash-Hinweis
- [ ] LiveView-Tests:
  - Bob (Participant) sieht in seiner Zeile drei Buttons mit korrekten DOM-IDs
  - Klick auf einen Button rendert ihn aktiv (Klassen-Assertion) und Footer-Score aktualisiert sich
  - Klick auf einen anderen Button überschreibt korrekt
  - Eingeloggter User ohne Participant-Persona sieht **keine** Buttons mit `vote-`-IDs in der Tabelle
  - Manipulierter `score`-Wert im Event führt zu keinem persistierten Vote
- [ ] `mix precommit` ist grün

## Blocked by

- [Issue 03](./03-availability-table-readonly.md) — baut auf der Tabelle und dem `current_persona`-Assign auf
