# Episode Availability Voting

Doodle-artige Verfügbarkeitsabstimmung für Episoden-Participants im Admin-Bereich.

- **Status**: Draft (Spec)
- **Erstellt**: 2026-05-28
- **Sprache**: UI-Strings via `gettext`; Code/Doku in Englisch, Beispiele in Deutsch
- **Bezug**: Erweitert `Radiator.Podcasts.Episode.Scheduling` um eine Voting-UI in `RadiatorWeb.Admin.Episodes.ShowLive`

## 1. Ziel und Nutzerwert

Wenn ein Owner ein Scheduling für eine Episode anlegt, schlägt er mehrere Datumsvorschläge vor und legt eine Liste von Participants fest. Jeder angemeldete Participant soll seine **Verfügbarkeit** zu jedem Vorschlag mit einem von drei Status markieren:

| Status      | Score | Bedeutung               |
| ----------- | ----: | ----------------------- |
| ja          |  `+1` | kann an dem Termin      |
| vielleicht  |   `0` | unsicher                |
| nein        |  `-1` | kann nicht              |
| _(kein Eintrag)_ |  – | hat noch nicht abgestimmt |

Die Stimmen aller Participants sind **offen sichtbar** für jeden angemeldeten User im Admin-Bereich (keine Anonymisierung; die Crew kennt sich). Der bevorzugte Termin ergibt sich als Vorschlag mit dem höchsten `SUM(score)`.

## 2. Scope

### 2.1 In Scope (v1)

- Persistente Verknüpfung `User ↔ Persona` (Voraussetzung, siehe §3.1)
- Datenmodell-Umbau von Score `1..5` auf Score `-1 / 0 / 1`
- Authorization: Edit-Recht nur für eigene Stimme
- UI-Sektion in `ShowLive` als Matrix-Tabelle mit drei Voting-Buttons in der eigenen Zeile
- Kalendarische Spaltenköpfe (Wochentag, Datum, Uhrzeit, Wochenende-Highlight)
- Mobile-Tauglichkeit durch horizontalen Scroll mit sticky Namensspalte
- Read-only-Darstellung, wenn `Scheduling.status = :closed`

### 2.2 Out of Scope (v1)

Folgendes ist bewusst zurückgestellt. Das Backend behält die Felder/Actions, aber die UI exponiert sie nicht:

- Kommentar pro Stimme (`Vote.comment` existiert weiter, nur kein Eingabefeld)
- Eigene Datumsvorschläge ergänzen (`add_proposal`-Action bleibt nutzbar)
- Vorschläge entfernen (`remove_proposal`)
- Scheduling abschließen / wieder öffnen über UI (`finalize` / `reopen`)
- Realtime-Updates via `Phoenix.PubSub`
- Multi-Persona pro User
- E-Mail- oder In-App-Benachrichtigung an Participants
- Eine eigene Mobile-Layout-Variante (über horizontalen Scroll hinaus)

## 3. Datenmodell-Änderungen

### 3.1 `Radiator.People.Persona`: optionale User-Verknüpfung

Aktuell gibt es keine Verbindung zwischen `Radiator.Accounts.User` und `Radiator.People.Persona`. Für dieses Feature wird `personas.user_id` als **optionale** Fremdschlüsselspalte ergänzt.

**Annahmen:**

- Ein User hat höchstens eine Persona (in v1). Eine spätere Migration zu Multi-Persona oder zu einer Person-vermittelten Verknüpfung (`users.id → people.user_id → personas.person_id`) ist möglich, ohne den Vote-Code zu brechen, weil der Vote-Code nur eine `persona_id` braucht.
- Eine Persona muss nicht zwingend einen User haben (z. B. externe Gäste).

**Schema-Änderungen:**

- Neue Spalte `personas.user_id :uuid` (nullable, FK auf `users.id`, `ON DELETE SET NULL`)
- Ash-Resource: Attribut `user_id` + `belongs_to :user, Radiator.Accounts.User, allow_nil?: true`
- `identity :unique_user, [:user_id]` (verbindlich; verhindert Multi-Persona-pro-User auf DB-Ebene; konsistent mit v1-Annahme)
- Read-Action `:by_user` mit `argument :user_id, :uuid` und `filter expr(user_id == ^arg(:user_id))`; via `code_interface define :get_by_user, args: [:user_id]` aufrufbar

**Migration:**

- Spalte hinzufügen, nullable
- Unique-Index auf `user_id` (entsteht aus der Identity automatisch)

### 3.2 `Radiator.Podcasts.Episode.Scheduling.Vote`: Score-Wertebereich

Bisher: `score :integer`, dokumentiert als 1..5 mit semantischem Mapping.
Neu: `score :integer` mit `constraints one_of: [-1, 0, 1]` und neuem Doku-Mapping.

**Begründung der Beibehaltung von `:integer`** (statt z. B. `:atom`-Enum):

- Top-Vorschlag-Berechnung wird zur simplen Summe pro Proposal — keine Mapping-Funktion `:yes → 1` nötig.
- Sortierung „beliebtester Termin zuerst" ist `ORDER BY SUM(score) DESC`-äquivalent in Elixir.

**Doku im Modulkopf neu fassen:**

```
-1 = no  (cannot attend)
 0 = maybe (unsure / tentative)
 1 = yes (can attend)

Keine Stimme im `votes`-Array bedeutet "noch nicht abgestimmt"
und wird NICHT als 0 mitgerechnet.
```

`comment :string` bleibt unverändert (Backend-Feld, in v1 nicht UI-exponiert).

### 3.3 `Radiator.Podcasts.Episode.Scheduling.Validations.ValidScore`

Wertebereich-Check anpassen: erlaubt sind ausschließlich `-1`, `0`, `1`. Fehlermeldung sinngemäß `"score must be -1, 0 or 1"`. Bestehende Aufrufer (`:vote`-Action in `Scheduling`, `:add_vote`-Action in `Proposal`) bleiben unverändert in der Signatur.

### 3.4 `Radiator.Podcasts.Episode.Scheduling`: Statistik und Actor-Auth

#### `voting_stats/1` umbauen

Bisher: `average_score :float`, Sortierung absteigend nach Average.
Neu: Pro Proposal liefert die Statistik mindestens diese Felder:

| Feld              | Typ       | Beschreibung                                          |
| ----------------- | --------- | ----------------------------------------------------- |
| `proposal_id`     | `uuid`    | ID des Vorschlags                                     |
| `datetime`        | `utc_datetime` | Datums-/Zeitvorschlag                            |
| `total_score`     | `integer` | Summe aller `score`-Werte (Hauptsortierkriterium)     |
| `yes_count`       | `integer` | Anzahl `score = 1`                                    |
| `maybe_count`     | `integer` | Anzahl `score = 0`                                    |
| `no_count`        | `integer` | Anzahl `score = -1`                                   |
| `pending_count`   | `integer` | Anzahl Participants ohne Stimme für diesen Vorschlag  |
| `votes`           | `list`    | Liste der einzelnen Vote-Structs (für die UI-Tabelle) |

Top-Level-Felder von `voting_stats` (Status, Aggregate über alle Proposals) bleiben sinngemäß erhalten, aber `top_proposal` referenziert den Vorschlag mit höchstem `total_score`. Bei Gleichstand mehrerer Proposals: `top_proposal_id` ist `nil` (keine eindeutige Hervorhebung).

#### Neue Helper-Funktion `top_proposal_id/1`

Gibt die `proposal_id` mit dem höchsten `total_score` zurück. Bei Gleichstand zwischen mehreren Proposals: `nil`.

#### `:vote`-Action: Actor-basierte Auth-Validation

**Problem:** Aktuell prüft `ParticipantOnly` nur, ob die im Argument übergebene `persona_id` in `participant_persona_ids` enthalten ist. Ein angemeldeter User könnte technisch eine fremde `persona_id` mitgeben und als jemand anderes abstimmen.

**Lösung:** Neue Validation `Radiator.Podcasts.Episode.Scheduling.Validations.PersonaBelongsToActor`:

- Liest `actor` aus `context`
- Liest `persona_id` aus dem Argument
- Lädt `Persona |> filter(id == ^persona_id and user_id == ^actor.id)` und prüft, dass genau eine Persona zurückkommt
- Schlägt mit klarer Fehlermeldung fehl, wenn der Actor nicht zur angegebenen Persona gehört

Reihenfolge in der `:vote`-Action (von billig nach teuer; Sicherheit ist in jeder Reihenfolge gegeben, weil alle vier durchlaufen werden müssen):

1. `attribute_equals(:status, :open)` — Scheduling muss offen sein
2. `ValidScore` — Score muss `-1 / 0 / 1` sein (reiner Wertebereichs-Check)
3. `ParticipantOnly` — diese Persona muss in `participant_persona_ids` enthalten sein (In-Memory-Check)
4. `PersonaBelongsToActor` — angegebene Persona muss dem aktuellen User gehören (DB-Lookup)

Die `change`-Logik der `:vote`-Action bleibt unverändert: vorhandene Stimme der Persona wird ersetzt (Replace-Semantik, idempotent).

### 3.5 Seeds (`priv/repo/seeds.exs`)

- Bob bekommt eine `Person` + `Persona`. Die Persona wird mit Bobs `User` verknüpft (`user_id: bob.id`).
- Bobs Persona-`id` wird **vor** der Scheduling-Erzeugung in die `participant_persona_ids`-Liste eingefügt (z. B. `[bob_persona.id | participant_ids]`), damit Bob auf der Episoden-Show-Seite tatsächlich abstimmen kann.
- Die existierenden Vote-Calls am Ende der Seeds nutzen jetzt `score: 1` (statt `5`), `score: 0` (statt `3`), `score: -1` (statt `1`).

## 4. Authorization-Matrix

| Wer                                                       | Sektion sichtbar | Eigene Buttons aktiv |
| --------------------------------------------------------- | ---------------- | -------------------- |
| Beliebiger angemeldeter User (im Admin-Bereich)           | ja               | nein                 |
| Angemeldeter User ohne verknüpfte Persona                 | ja               | nein                 |
| Angemeldeter User mit Persona, aber nicht Participant     | ja               | nein                 |
| Angemeldeter User mit Persona = Participant, Status `:open` | ja             | ja                   |
| Angemeldeter User mit Persona = Participant, Status `:closed` | ja           | nein (disabled)      |
| Nicht angemeldete Besucher                                | n/a (Login-Wall) | n/a                  |

`finalize`/`reopen`/`add_proposal`/`remove_proposal` sind in v1 nicht über die UI erreichbar, unabhängig vom Owner-Status.

## 5. UI

### 5.1 Position und Trigger

- Datei: `lib/radiator_web/live/admin/episodes/show_live.html.heex`
- Die existierende `<section>` „Proposals" (Z. 46–56 zum Zeitpunkt der Spec) wird **ersetzt** durch eine neue `<section>` mit dem Header `gettext("Availability")`.
- Die nachfolgende `<section>` „Participants" bleibt unverändert.
- Die neue Sektion wird gerendert, wenn `@episode.scheduling != nil`. `Episode.state` wird nicht ausgewertet — der einzige Trigger für Interaktivität ist `Scheduling.status = :open`.

### 5.2 Mount und Assigns

`show_live.ex` ergänzt im `mount/3`:

- Aktuelle Persona des Users laden: `current_persona = Persona.get_by_user(current_user)` (kann `nil` sein)
- `current_persona` als Assign setzen
- `episode` lädt zusätzlich `scheduling.proposals` (bereits embedded, also implizit; nur sicherstellen)
- Helper-Funktionen im LiveView- oder Component-Modul:
  - `participant?(episode, persona)` — `persona && persona.id in (episode.participants |> Enum.map(& &1.id))`
  - `can_vote?(scheduling, persona)` — Status `:open` und `participant?`
  - `vote_for_persona(proposal, persona_id)` — gibt `nil | %Vote{}` zurück; UI nutzt das, um den aktiven Button zu markieren

### 5.3 Tabellen-Struktur

```
                     ┌─────────────┬─────────────┬─────────────┐
                     │ Fr 17.04.   │ Sa 18.04.*  │ So 19.04.*  │   * = Wochenende-Highlight
                     │ 22:17       │ 22:17       │ 19:00       │   ★ = Top-Vorschlag (border-primary)
─────────────────────┼─────────────┼─────────────┼─────────────┤
Bob   (du)           │ [✓][?][✗]  │ [✓][?][✗]  │ [✓][?][✗]  │
Jim                  │    ✓        │    ?        │    ✗        │
Alice                │    ✓        │    –        │    ✓        │
Carol                │    ?        │    ✓        │    ✗        │
─────────────────────┼─────────────┼─────────────┼─────────────┤
Score                │    +2 ★    │    +1       │    -1       │
```

**CSS-Hinweise (Tailwind / DaisyUI):**

- Wrapper `<div class="overflow-x-auto">` um die Tabelle herum
- `<table class="table table-zebra">`
- Erste Spalte: `<th class="sticky left-0 bg-base-100 z-10">` für Namen
- Wochenende-Spaltenkopf: zusätzliche Klasse `bg-base-200`
- Top-Vorschlag-Spalte: Klasse `border-2 border-primary` auf Kopf und Footer-Zelle, optional Krone-Icon (`<.icon name="hero-trophy" />`)
- Buttons in eigener Zeile: `btn-group` mit drei `<button>`s, aktiver Button bekommt `btn-primary`/`btn-success`/`btn-error`/`btn-warning` je nach Status; inaktive `btn-ghost`
- Statussymbol-Mapping in Anzeige-Zellen: `1` → `<.icon name="hero-check" class="text-success">`, `0` → `<.icon name="hero-question-mark" class="text-warning">`, `-1` → `<.icon name="hero-x-mark" class="text-error">`, kein Vote → `<span class="opacity-40">–</span>`
- Wenn `Scheduling.status = :closed`: alle eigenen Buttons `disabled`; `chosen_proposal_id` bekommt zusätzlich ein `badge badge-primary` „Gewählt" im Spaltenkopf

### 5.4 Interaktion

Drei `<button>`s pro Vote-Zelle (in der eigenen Zeile), z. B.:

```heex
<button
  id={"vote-#{proposal.id}-yes"}
  type="button"
  class={["btn btn-sm", active_class(:yes, current_vote)]}
  phx-click="vote"
  phx-value-proposal-id={proposal.id}
  phx-value-score="1"
  disabled={not can_vote?(@episode.scheduling, @current_persona)}
>
  <.icon name="hero-check" />
</button>
```

**Wichtige UX-Festlegungen:**

- Stabile DOM-IDs in der Form `vote-<proposal_id>-<status>` für LiveView-Tests
- Score wird als String über `phx-value-score` übertragen und im `handle_event` mit `String.to_integer/1` konvertiert; Whitelist `[-1, 0, 1]` als Schutz vor manipulierten Werten (zusätzlich zur Server-Validation)
- Kein expliziter „unvote"-Button in v1 — eine Stimme bleibt, bis die Persona einen anderen Status wählt. Konsequenz: einmal abgestimmt = nie wieder „pending".
- Idempotenter Klick (gleicher Status nochmal) ist erlaubt und bleibt ein No-Op auf DB-Ebene durch die Replace-Logik der `:vote`-Action.

### 5.5 `handle_event/3`

```elixir
def handle_event("vote", %{"proposal-id" => pid, "score" => score_str}, socket) do
  with score when score in [-1, 0, 1] <- String.to_integer(score_str),
       persona when not is_nil(persona) <- socket.assigns.current_persona,
       {:ok, _scheduling} <-
         Scheduling.vote(socket.assigns.episode.scheduling, pid, persona.id, score,
           actor: socket.assigns.current_user
         ) do
    {:noreply, reload_episode(socket)}
  else
    _ -> {:noreply, put_flash(socket, :error, gettext("Could not record your vote."))}
  end
end
```

`reload_episode/1` lädt die Episode mit denselben Loads neu (`[:podcast, :participants, :scheduling]`) und ersetzt das `:episode`-Assign. Das ist nicht optimal performant, aber simpel, korrekt und für v1 ausreichend (eine Stimme = ein DB-Read).

## 6. Tests

Test-Strategie: TDD (Red → Green → Refactor) in drei Schichten.

### 6.1 Resource-Tests

Pfad: `test/radiator/podcasts/episode/scheduling_test.exs`

Mindestens diese Cases (neue Datei, da bisher keine Tests):

- `vote/4` mit `score: 1` schreibt einen Vote-Eintrag in `proposals[].votes`
- `vote/4` mit `score: 0` und `score: -1` analog
- `vote/4` mit `score: 2` schlägt fehl (`ValidScore`)
- `vote/4` mit `score: nil` schlägt fehl (`allow_nil?: false`)
- `vote/4` zweimal hintereinander mit unterschiedlichen Scores: nur die letzte Stimme bleibt (Replace-Semantik)
- `vote/4` mit `persona_id` einer Persona, die nicht zum Actor gehört, schlägt fehl (`PersonaBelongsToActor`)
- `vote/4` ohne Actor schlägt fehl (oder im Test mit anderem Actor)
- `vote/4` bei `status: :closed` schlägt fehl
- `voting_stats/1` liefert `total_score`, `yes_count`, `no_count`, `maybe_count`, `pending_count` korrekt
- `top_proposal_id/1` bei eindeutigem Sieger korrekt
- `top_proposal_id/1` bei Gleichstand: `nil`

### 6.2 Persona-Lookup-Tests

Pfad: `test/radiator/people/persona_test.exs` (neu)

- `get_by_user(user)` findet Persona, wenn `user_id` gesetzt ist
- `get_by_user(user)` gibt `nil` (oder `{:error, _}`), wenn keine Persona verknüpft ist

### 6.3 LiveView-Tests

Pfad: `test/radiator_web/live/admin/episodes/show_live_test.exs` (neu)

Setup: User Bob + verknüpfte Persona + Episode + Scheduling mit drei Proposals; Bob als Participant.

- Eingeloggter Bob (Participant) sieht in seiner Zeile drei Buttons mit IDs `vote-<id>-yes`/`-maybe`/`-no`
- Klick auf `vote-<id>-yes`: Button wird zum aktiven Zustand, Score-Footer aktualisiert sich
- Klick auf `vote-<id>-no` nach `yes`: alter Yes-Zustand verschwindet, No ist aktiv
- Eingeloggter Jim (kein Participant, aber mit Persona) sieht die Tabelle, aber keine Buttons mit eigenen IDs
- Eingeloggter User ohne verknüpfte Persona sieht ebenfalls keine eigenen Buttons
- `Scheduling.status = :closed`: Buttons sind `disabled`; das `chosen_proposal_id` hat das „Gewählt"-Badge
- Wochenende-Spalten haben die Highlight-Klasse (CSS-Klasse-Assertion via `LazyHTML`)

### 6.4 Validation-Tests

Pfad: `test/radiator/podcasts/episode/scheduling/validations/persona_belongs_to_actor_test.exs` (neu)

- Passt: persona.user_id == actor.id
- Schlägt fehl: persona.user_id != actor.id
- Schlägt fehl: persona.user_id == nil

## 7. Risiken und offene Punkte

| Risiko / Punkt | Bewertung | Mitigation |
| --- | --- | --- |
| Keine bestehenden Vote-Daten in Produktion (kein Live-Deployment) | Niedrig | Migration bleibt destruktiv-frei; JSONB-Daten werden nicht angefasst |
| Existierende Seeds nutzen Scores 4/5/3 → wären nach Migration invalid | Niedrig | Seeds werden in Schritt 1 angepasst (Teil der gleichen Änderung) |
| `Persona`-Lookup per User wird ohne Cache in jedem Mount aufgerufen | Niedrig | Ein DB-Hit pro Mount; bei Bedarf später `assign_new` oder Session-Cache |
| Mobile-Tauglichkeit nur via horizontalem Scroll | Akzeptiert | Sticky Namensspalte mildert; alternativer Mobile-Layout-Mode = Out of Scope |
| Multi-Persona pro User später gewünscht | Akzeptiert | Migration zu `users → people → personas` ist möglich, ohne Vote-API zu brechen, weil nur `persona_id` benutzt wird |
| `ParticipantOnly` und `PersonaBelongsToActor` haben Reihenfolge-Abhängigkeit | Niedrig | Beide Validations sind in der Action explizit nacheinander deklariert |

## 8. Implementierungs-Reihenfolge (für späteren Plan)

1. Migration `personas.user_id` + Schema-Update `Persona` + Code-Interface `get_by_user` + Tests
2. Seeds anpassen (Bob ↔ Persona-Verknüpfung; Vote-Scores auf -1/0/1)
3. `ValidScore` auf `one_of: [-1, 0, 1]` umbauen + `Vote.score`-Constraint + zugehörige Tests
4. `voting_stats` und `top_proposal_id` umbauen + Tests
5. Validation `PersonaBelongsToActor` + Tests
6. `:vote`-Action um neue Validation erweitern + Tests
7. `ShowLive` mount-Logik um `current_persona` + Helper erweitern
8. UI-Sektion bauen (Markup + `handle_event` + Component-Helper)
9. LiveView-Tests
10. `mix precommit` grün

## 9. Akzeptanzkriterien (Definition of Done)

- [ ] Migration angewendet, `personas.user_id` existiert als nullable FK
- [ ] Bob aus den Seeds hat eine Persona mit `user_id`; nach `mix ecto.reset` ist Bob als Persona-Participant in `future_episode`-Scheduling eingetragen
- [ ] `Vote.score` akzeptiert nur `-1 / 0 / 1`; alles andere schlägt mit klarer Fehlermeldung fehl
- [ ] `Scheduling.voting_stats/1` liefert `total_score / yes_count / no_count / maybe_count / pending_count` pro Proposal
- [ ] Bob kann sich anmelden, zur `future_episode`-Show-Seite navigieren und sieht eine Tabelle mit drei Vorschlägen, eigenen Buttons und Stimmen der anderen Test-Personas
- [ ] Bob kann durch Klick auf einen Button seinen Status setzen und ändern; der Score-Footer aktualisiert sich
- [ ] Ein anderer angemeldeter User (z. B. Jim, falls ohne Participant-Persona) sieht die Tabelle ohne eigene Buttons
- [ ] Bei `Scheduling.status = :closed` sind alle Buttons `disabled`; das gewählte Proposal ist als „Gewählt" markiert
- [ ] Wochenende-Spalten sind visuell hervorgehoben
- [ ] Alle in §6 aufgeführten Tests sind grün
- [ ] `mix precommit` ist grün (compile, format, credo, test)
