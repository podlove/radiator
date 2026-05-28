# Issue 01: Persona ↔ User Verknüpfung (Foundation)

## Parent

[Epic: Episode Availability Voting](./00-epic.md)

## What to build

Aktuell gibt es keine Beziehung zwischen `Radiator.Accounts.User` (E-Mail/Passwort-Auth) und `Radiator.People.Persona` (öffentliche Identität). Das blockiert das gesamte Voting-Feature, weil im Voting jede Stimme zu einer `Persona` gehört und der angemeldete User irgendwie auf seine Persona gemappt werden muss.

Dieser Slice schafft die einfachste mögliche Verknüpfung: eine **optionale `user_id`-Spalte** auf `personas`. Jeder User hat höchstens eine Persona (v1-Annahme); jede Persona kann genau einem User gehören oder zu keinem (z. B. externe Gäste).

Demoable in iex: `Persona.get_by_user(bob_user)` liefert Bobs Persona.

### Konkrete Änderungen

- **Migration**: Spalte `personas.user_id :uuid` (nullable, FK auf `users.id`, `ON DELETE SET NULL`)
- **Ash-Resource `Radiator.People.Persona`**:
  - Attribut `user_id, :uuid, allow_nil?: true, public?: true`
  - Relation `belongs_to :user, Radiator.Accounts.User, allow_nil?: true`
  - Identity `identity :unique_user, [:user_id]` (erzwingt 1:1 auf DB-Ebene, erzeugt automatisch Unique-Index)
  - Read-Action `:by_user, argument :user_id, :uuid, filter expr(user_id == ^arg(:user_id))`
  - Code-Interface `define :get_by_user, args: [:user_id]`
- **Seeds (`priv/repo/seeds.exs`)**:
  - Vor der `future_episode`-Scheduling-Erzeugung: Bob bekommt eine `Person` + `Persona`; die Persona wird mit Bobs User über `user_id: bob.id` verknüpft
  - Bobs Persona-ID wird in die `participant_persona_ids`-Liste des `future_episode`-Schedulings aufgenommen (damit Bob in Issue 04 tatsächlich abstimmen kann)

## Acceptance criteria

- [ ] Migration vorhanden und idempotent ausführbar (`mix ash.codegen` oder manuell, je nach Projekt-Konvention)
- [ ] `mix ash.setup` läuft fehlerfrei durch
- [ ] `personas.user_id` ist nullable mit `ON DELETE SET NULL`
- [ ] Identity `unique_user` verhindert zwei Personas mit derselben `user_id` (Test gegen Identity-Violation)
- [ ] `Radiator.People.Persona.get_by_user(bob.id)` gibt Bobs Persona zurück; ohne Verknüpfung liefert `{:error, %Ash.Error.Query.NotFound{}}` oder vergleichbar (klare API-Semantik)
- [ ] Tests in `test/radiator/people/persona_test.exs`:
  - `get_by_user` findet eine verknüpfte Persona
  - `get_by_user` mit unbekannter User-ID liefert klares Fehler-/Nil-Ergebnis
  - Anlegen zweier Personas mit derselben `user_id` schlägt fehl
- [ ] `mix ecto.reset` legt Bob mit verknüpfter Persona und als Participant im `future_episode`-Scheduling an
- [ ] `mix precommit` ist grün

## Blocked by

None - can start immediately
