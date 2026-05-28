# Issue 05: Read-only-Mode bei :closed + Gewinner-Markierung

## Parent

[Epic: Episode Availability Voting](./00-epic.md)

## What to build

Wenn das Scheduling über `Scheduling.finalize/2` geschlossen wurde (`status: :closed`, `chosen_proposal_id` gesetzt), darf niemand mehr abstimmen — und der gewählte Termin muss visuell klar erkennbar sein. Die `finalize`-Aktion selbst bleibt v1-mäßig nicht über die UI ausführbar (siehe Spec §2.2), sondern wird manuell via iex oder AshAdmin getriggert. Dieser Slice baut nur den **UI-State** für „bereits geschlossen".

Demoable: Nach `Scheduling.finalize(scheduling, chosen_proposal.id, owner_persona.id)` via iex sieht Bob beim Reload der Show-Seite alle Voting-Buttons als `disabled`. Die Spalte des `chosen_proposal_id` bekommt ein zusätzliches „Gewählt"-Badge im Spaltenkopf (zusätzlich oder anstelle des Top-Vorschlag-Highlights).

### Konkrete Änderungen

- **`RadiatorWeb.Admin.Episodes.ShowLive`** (bzw. Helper aus Issue 03):
  - Helper `can_vote?(scheduling, persona)` erweitern (oder nutzen): liefert nur `true`, wenn `scheduling.status == :open` UND `persona` ist Participant UND `persona` ist gesetzt
  - `disabled={not can_vote?(...)}` an alle drei Voting-Buttons in der eigenen Zeile binden
  - Im Spaltenkopf des `chosen_proposal_id`: zusätzliches `<.badge>` (oder vergleichbar) mit Text `gettext("Chosen")`/`gettext("Gewählt")`
  - Wenn `scheduling.status == :closed` UND `chosen_proposal_id` gesetzt: das vom Top-Vorschlag-Highlight (aus Issue 03) abgeleitete „Sieger"-Highlight wird zum `chosen_proposal_id` umgemappt (Owner-Entscheidung schlägt automatisches Ranking)
  - Wenn `scheduling.status == :closed` UND `chosen_proposal_id == nil` (Edge-Case Reopen mit Reset): kein „Gewählt"-Badge, kein eigenes Sieger-Highlight; alle Buttons disabled

### Außerhalb dieses Schnitts

- Kein UI-Button für `finalize` / `reopen` (siehe Spec §2.2 Out of Scope)
- Keine Mail-/PubSub-Notification beim Status-Wechsel

## Acceptance criteria

- [ ] `can_vote?/2` liefert `false`, sobald `scheduling.status == :closed`, unabhängig von Participant-Status
- [ ] Bei `:closed`: alle drei Buttons in der eigenen Zeile haben `disabled`-Attribut (HTML-Attribut-Assertion)
- [ ] Bei `:closed`: Klick auf einen Button (z. B. via `render_click`) führt zu keinem persistierten Vote (Aktion schlägt server-seitig bereits durch `attribute_equals(:status, :open)` fehl — Test bestätigt das)
- [ ] Bei `:closed` mit gesetztem `chosen_proposal_id`: der Spaltenkopf des gewählten Vorschlags zeigt ein „Gewählt"-Badge (Text/Lokalisierung via `gettext`)
- [ ] Bei `:closed` mit gesetztem `chosen_proposal_id`: das Sieger-Highlight verschiebt sich vom automatisch berechneten Top-Vorschlag auf den `chosen_proposal_id` (visuelle Konsistenz: Owner-Entscheidung ist die Wahrheit)
- [ ] Bei `:closed` ohne `chosen_proposal_id`: kein Badge, kein zusätzliches Highlight (Edge-Case sauber)
- [ ] LiveView-Tests in `test/radiator_web/live/admin/episodes/show_live_test.exs` (Erweiterung):
  - Scheduling mit `status: :open` rendert Buttons ohne `disabled`
  - Scheduling mit `status: :closed` rendert alle Buttons mit `disabled`
  - Scheduling mit `status: :closed` und `chosen_proposal_id`: Badge ist auf der korrekten Spalte
  - Scheduling mit `status: :closed` und `chosen_proposal_id`: Sieger-Highlight ist auf der gewählten Spalte (auch wenn ein anderer Vorschlag den höheren `total_score` hätte)
- [ ] `mix precommit` ist grün

## Blocked by

- [Issue 04](./04-vote-interaction.md) — baut auf den Voting-Buttons und der `can_vote?`-Logik auf
