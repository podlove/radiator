# Issue 03: Verfügbarkeits-Matrix-Tabelle anzeigen (read-only)

## Parent

[Epic: Episode Availability Voting](./00-epic.md)

## What to build

Auf der Episoden-Show-Seite (`RadiatorWeb.Admin.Episodes.ShowLive`) wird die bestehende `<section>` „Proposals" durch eine **Matrix-Tabelle** ersetzt, die auf einen Blick zeigt, wer wann verfügbar ist. **Noch keine interaktiven Buttons** — der Schnitt liefert ausschließlich die Anzeige.

Die Tabelle muss kalendarisch lesbar sein: Wochentag, Datum, Uhrzeit; Wochenenden visuell hervorgehoben; Sieger-Spalte markiert; Footer mit Summen-Score pro Spalte; Namensspalte links sticky beim horizontalen Scroll. Mobile-Tauglichkeit nur über horizontalen Scroll (kein eigener Mobile-Layout-Mode).

Demoable: Bob meldet sich an, navigiert zur `future_episode`-Show-Seite, sieht die fertige Tabelle mit den Stimmen aus den Seeds (Issue 02), die korrekt aggregiert sind. Bobs eigene Zeile zeigt zunächst nur „–" (er hat noch nicht abgestimmt — interaktive Buttons kommen in Issue 04).

### Konkrete Änderungen

- **`RadiatorWeb.Admin.Episodes.ShowLive` (`mount/3`)**:
  - Zusätzlich `current_persona = Persona.get_by_user(current_user)` als Assign (kann `nil` sein, wenn User keine Persona verknüpft hat)
  - Episode-Load bleibt `[:podcast, :participants, :scheduling]`
- **Helper-Funktionen** (im LiveView-Modul oder in einem neuen `RadiatorWeb.Admin.Episodes.AvailabilityHelpers`):
  - `participant?(episode, persona)`
  - `vote_for_persona(proposal, persona_id) :: nil | %Vote{}`
  - Optionale Format-Helfer für Wochentag, Score-Symbol, Wochenende-Check
- **`show_live.html.heex`**:
  - Die bestehende `<section>` „Proposals" (Z. 46–56 zum Zeitpunkt der Spec) wird **ersetzt** durch eine neue `<section>` mit `gettext("Availability")` als Überschrift
  - Die Sektion wird gerendert, wenn `@episode.scheduling != nil` (Status ist egal — bei `:closed` sieht es genauso aus, ohne Buttons; das „Gewählt"-Badge kommt erst in Issue 05)
  - Matrix-Tabelle gemäß Spec §5.3:
    - Wrapper `<div class="overflow-x-auto">`
    - Header pro Spalte: Wochentag (`gettext`-lokalisiert via `Cldr` oder lokal-gepflegte Map), Datum, Uhrzeit
    - Wochenende-Spaltenkopf: zusätzliche Klasse (z. B. `bg-base-200`)
    - Top-Vorschlag-Spalte (höchste `total_score`): Klasse `border-2 border-primary`, optionales Trophy-Icon
    - Eine Zeile pro Participant; Namen-Spalte sticky `left-0 bg-base-100 z-10`
    - Bobs Zeile (current_persona == participant) wird optisch markiert (z. B. mit `(du)`-Suffix oder fettem Namen) — **noch ohne Buttons**
    - Status-Icons in den Zellen: `1` → `hero-check` `text-success`, `0` → `hero-question-mark` `text-warning`, `-1` → `hero-x-mark` `text-error`, kein Vote → `<span class="opacity-40">–</span>`
    - Footer-Zeile: leeres Namens-Feld, dann pro Spalte `total_score` (z. B. `+2`); Sieger-Spalte fett oder mit Badge
  - Die separate `<section>` „Participants" bleibt unverändert darunter

### Außerhalb dieses Schnitts

- Keine `<button>`s, kein `phx-click`, kein `handle_event` für Voting (kommt in Issue 04)
- Kein Disabled-State, kein „Gewählt"-Badge (kommt in Issue 05)
- Kein PersonaBelongsToActor (kommt in Issue 04)

## Acceptance criteria

- [ ] `show_live.ex` lädt `current_persona` im Mount und legt es als Assign ab
- [ ] Die bestehende Sektion „Proposals" ist entfernt und durch die neue Sektion „Availability" ersetzt
- [ ] Tabelle rendert bei drei Proposals und drei Participants korrekt (Header, Zeilen, Footer)
- [ ] Wochentag-Kürzel im Header sind korrekt für die jeweiligen Datums (manueller Visual-Check + Snapshot-/CSS-Klassen-Test)
- [ ] Wochenende-Spalten haben eine erkennbare Highlight-Klasse (CSS-Klassen-Assertion via `LazyHTML`)
- [ ] Top-Vorschlag (höchste `total_score`) hat eine Highlight-Klasse im Spaltenkopf und im Footer
- [ ] Status-Icons sind korrekt pro `Vote.score`-Wert; Personas ohne Vote bekommen das „–"-Symbol
- [ ] Footer-Score-Zelle pro Spalte zeigt `total_score` korrekt (mit Vorzeichen, z. B. `+2`, `0`, `-1`)
- [ ] Namensspalte ist `sticky left-0` (CSS-Klassen-Assertion)
- [ ] Tabelle ist in einem `overflow-x-auto`-Wrapper eingebettet
- [ ] Wenn `current_persona` Participant ist: Bobs Namen-Zelle ist optisch markiert (z. B. Suffix `(du)`); **noch keine Buttons**
- [ ] Wenn `current_persona == nil` oder kein Participant: Tabelle rendert ohne Markierung, ohne Buttons
- [ ] LiveView-Tests in `test/radiator_web/live/admin/episodes/show_live_test.exs` (neue Datei): Rendering mit Bob als Participant, Rendering ohne Persona, Wochenende-Highlight, Top-Vorschlag-Highlight, „–"-Symbol für Personas ohne Vote
- [ ] `mix precommit` ist grün

## Blocked by

- [Issue 01](./01-persona-user-link.md) — benötigt `Persona.get_by_user`
- [Issue 02](./02-score-model-and-stats.md) — benötigt `voting_stats` mit `total_score`, `pending_count`, `top_proposal_id`
