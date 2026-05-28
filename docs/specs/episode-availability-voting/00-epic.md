# Epic: Episode Availability Voting

Doodle-artige Verfügbarkeitsabstimmung für Episoden-Participants im Admin-Bereich.

## Quellen

- **Design-Spec**: [`../episode-availability-voting.md`](../episode-availability-voting.md)

## Ziel

Participants einer Episode können ihre Verfügbarkeit zu vorgeschlagenen Aufnahme-Terminen mit drei Status markieren (`+1 = ja`, `0 = vielleicht`, `-1 = nein`). Alle Stimmen sind für eingeloggte User offen sichtbar; jeder darf nur seine eigene Stimme bearbeiten. Der bevorzugte Termin ergibt sich aus `SUM(score)` pro Vorschlag.

## Sub-Issues (Reihenfolge nach Abhängigkeiten)

- [ ] **01** – [Persona ↔ User Verknüpfung (Foundation)](./01-persona-user-link.md)
- [ ] **02** – [Score-Modell auf -1/0/1 + neue Voting-Statistik](./02-score-model-and-stats.md)
- [ ] **03** – [Verfügbarkeits-Matrix-Tabelle anzeigen (read-only)](./03-availability-table-readonly.md)
- [ ] **04** – [Eigene Stimme abgeben (Voting-Interaktion)](./04-vote-interaction.md)
- [ ] **05** – [Read-only-Mode bei :closed + Gewinner-Markierung](./05-closed-mode-and-winner.md)

## Abhängigkeitsdiagramm

```
01 ──┐
     ├──> 03 ──> 04 ──> 05
02 ──┘
```

- 01 und 02 sind voneinander unabhängig und können parallel laufen
- 03 braucht beide als Voraussetzung
- 04 baut auf 03 auf (Auth + Interaktion)
- 05 baut auf 04 auf (Status-Variante)

## Definition of Done (Epic-Ebene)

- [ ] Alle fünf Sub-Issues abgeschlossen
- [ ] `mix precommit` grün (compile, format, credo, test)
- [ ] Bob aus den Seeds kann sich anmelden, zur `future_episode`-Show-Seite navigieren, seine Verfügbarkeit für alle drei Vorschläge setzen und seinen Status sofort sehen
- [ ] Eine andere eingeloggte Persona (Nicht-Participant) sieht die gleiche Tabelle ohne eigene Buttons
- [ ] Nach `Scheduling.finalize` (manuell via iex) ist die Tabelle read-only und der gewählte Vorschlag markiert
- [ ] Spec [`../episode-availability-voting.md`](../episode-availability-voting.md) bleibt mit dem Code konsistent (alle Akzeptanzkriterien aus §9 der Spec erfüllt)

## Out of Scope (siehe §2.2 der Spec)

- Kommentar pro Stimme (UI)
- Eigene Datumsvorschläge ergänzen (UI)
- Scheduling abschließen / wieder öffnen über UI
- Realtime-Updates via PubSub
- Multi-Persona pro User
- Benachrichtigungen an Participants
