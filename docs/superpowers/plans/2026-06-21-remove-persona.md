# Persona entfernen – Domain-Layer aufräumen (Implementierungsplan, Rev. 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Bei Domain-Änderungen IMMER zuerst die Skill `ash-framework` konsultieren, bei Web/Auth-Routing die Skill `phoenix-framework`.

**Goal:** Das `Persona`-Konzept vollständig entfernen. `User` (pseudonymer Account) wird der Akteur im Scheduling; `Person` wird ein eigenständiger, referenzierbarer Datensatz für reale Menschen, optional mit einem User verknüpft. Beim Anlegen einer Episode werden unbekannte Teilnehmer-E-Mails als passwortlose User erzeugt und per Magic-Link zur Abstimmung eingeladen.

**Architecture:** `User` erhält pseudonyme Felder (`handle`, `avatar_url`), optionalen `person_id`-FK, eine `magic_link`-Auth-Strategy (passwortlos möglich → `hashed_password` wird optional) und Actions `:invite_by_email` / `:update_profile`. Das Episode-Formular löst Teilnehmer per `handle` oder `email` auf; unbekannte E-Mails werden via `manage_relationship` als User angelegt. Nach erfolgreichem Speichern verschickt `Podcasts.invite_new_participants/1` an die frisch angelegten User eine „hier kannst du abstimmen"-Mail mit Magic-Link, der direkt auf die Abstimmungsseite der Episode führt. Alle `*persona*`-Referenzen im Scheduling/Episode-Modell werden zu `*user*`. Resource `People.Persona`, Tabelle `personas` und Snapshots werden gelöscht.

**Tech Stack:** Elixir, Ash (`ash`, `ash_postgres`, `ash_phoenix`, `ash_authentication`, `ash_authentication_phoenix`, `ash_admin`, `ash_state_machine`), Phoenix LiveView, PostgreSQL, Swoosh/Mailer.

## Global Constraints

- Strukturmigrationen IMMER über `mix ash.codegen <name>` generieren; Snapshots unter `priv/resource_snapshots/` mitpflegen. Nur die Daten-Migration in Task 14 wird von Hand geschrieben.
- Auth-Strategy/Sender per Igniter-Task scaffolden (`mix ash_authentication.add_strategy magic_link`) statt von Hand — danach den generierten Code lesen und an die exakten Namen/Signaturen dieser Version anpassen.
- Nach jeder Resource-Änderung `mix compile --warnings-as-errors` grün halten.
- Abschluss jeder Task: relevante Tests grün (`mix test <pfad>`), dann committen.
- Am Ende: `mix precommit` grün.
- HTTP via `Req` (hier nicht relevant). Sprache bestehender Strings beibehalten (gemischt DE/EN).

## Zielmodell

```
User (pseudonymer Account + Akteur)              Person (realer Mensch, referenzierbar)
  - email (Login, unique)                          - first_name
  - hashed_password (OPTIONAL – Magic-Link)        - last_name
  - confirmed_at                                   - display_name   (z.B. "Harald Lesch")
  - handle (optional, unique)                      - homepage_url
  - avatar_url (optional)                          - wikipedia_url
  - person_id ──belongs_to──> Person (opt, unique) - bio
  - calc :display_name (person.display_name        <── has_one :user
        || handle || email)
  - m2m :episodes (Teilnehmer)
  - Strategien: password + magic_link (registration_enabled?)
  - Actions: :invite_by_email, :update_profile, :sign_in_with_magic_link, :request_magic_link
```

- `Episode.participants` : `many_to_many User` über `EpisodeParticipant`
- `EpisodeParticipant`    : `belongs_to :user` (+ `:role`, `has_one :track`)
- `Scheduling`           : `owner_user_id`, `participant_user_ids`, `belongs_to :owner_user`
- `Proposal` (embedded)  : `created_by_user_id`
- `Vote` (embedded)      : `user_id`

## Entschiedene Punkte

1. Akteur = **User**; FK **`person_id` auf User**; **Magic-Link als Login + Onboarding**.
2. User-Felder pseudonym: `email`, `hashed_password` (optional), `handle`, `avatar_url`. **Kein** `public_name`/`description`.
3. Person-Felder: **„Öffentliche Figur"** (`first_name`, `last_name`, `display_name`, `homepage_url`, `wikipedia_url`, `bio`). *(Per Empfehlung gewählt; an einer Stelle ohne explizite Bestätigung — vor Umsetzung kurz verifizieren.)*
4. Teilnehmer-Flow: beim Episode-Speichern unbekannte E-Mails als passwortlose User anlegen; nach Speichern Magic-Link-Mail → Login als genau dieser User + Deep-Link zur Abstimmung.
5. `participant_user_ids` (Array) **und** `EpisodeParticipant` bleiben beide (nur Rename) — Vereinheitlichung ist Folge-Cleanup (Task 15, optional). Acting-Identity bleibt als `user_id`-Argument (statt aus `context.actor` abgeleitet) — ebenfalls Task 15.

---

## Phase A — Accounts/User-Fundament

### Task 1: Magic-Link-Strategy + passwortloser User + Sender

**Files:**
- Modify: `lib/radiator/accounts/user.ex`
- Create: `lib/radiator/accounts/user/senders/send_magic_link.ex`
- (Igniter ändert ggf. Router/AuthController — danach prüfen.)

**Interfaces:**
- Produces: `magic_link`-Strategy mit `identity_field :email`, `registration_enabled? true`, `require_interaction? true`, `sender SendMagicLink`; Actions `:sign_in_with_magic_link` (Upsert-Create) und `:request_magic_link`; `hashed_password` `allow_nil? true`.

- [ ] **Step 1: Strategy scaffolden** — `mix ash_authentication.add_strategy magic_link`
Erwartet: fügt `magic_link do … end` in `strategies` ein, erzeugt einen Sender-Stub, ggf. Router-Routen/AuthController-Anpassungen. **Den generierten Diff lesen** und die exakten Action-Namen notieren (`auto_confirm_actions` in `user.ex` listet bereits `:sign_in_with_magic_link` — passt).

- [ ] **Step 2: hashed_password optional machen** — in `lib/radiator/accounts/user.ex`:

```elixir
    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
    end
```

- [ ] **Step 3: Strategy-Konfig prüfen/setzen** — im `magic_link`-Block sicherstellen:

```elixir
      magic_link do
        identity_field :email
        registration_enabled? true
        require_interaction? true
        sender Radiator.Accounts.User.Senders.SendMagicLink
      end
```

- [ ] **Step 4: Sender implementieren** — `lib/radiator/accounts/user/senders/send_magic_link.ex` nach dem Muster von `send_password_reset_email.ex`:

```elixir
defmodule Radiator.Accounts.User.Senders.SendMagicLink do
  @moduledoc "Sends a magic link sign-in email."
  use AshAuthentication.Sender
  use RadiatorWeb, :verified_routes

  import Swoosh.Email
  alias Radiator.Mailer

  @impl true
  def send(user_or_email, token, _opts) do
    email = to_email(user_or_email)

    new()
    |> to(to_string(email))
    |> from({"Radiator", "noreply@radiator.de"})
    |> subject("Dein Login-Link")
    |> html_body("""
      <p>Hier kannst du dich anmelden:</p>
      <p><a href="#{url(~p"/auth/user/magic_link?token=#{token}")}">Anmelden</a></p>
    """)
    |> Mailer.deliver()
  end

  defp to_email(%{email: email}), do: email
  defp to_email(email), do: email
end
```

> Hinweis: Die konkrete Route (`/auth/user/magic_link?token=…`) aus dem in Step 1 generierten Router verifizieren. Diese generische Mail wird in Task 11 für den Episode-Deep-Link erweitert/ersetzt.

- [ ] **Step 5: Kompilieren** — `mix compile --warnings-as-errors`.

- [ ] **Step 6: Migration** — `mix ash.codegen magic_link_passwordless` (macht `hashed_password` nullable). Erwartet: `alter`-Migration.

- [ ] **Step 7: Commit**

```bash
git add lib/radiator/accounts priv/repo/migrations priv/resource_snapshots lib/radiator_web mix.exs config
git commit -m "feat(accounts): add magic_link strategy and allow passwordless users"
```

---

### Task 2: User – pseudonyme Felder, Person-Link, Actions, display_name

**Files:**
- Modify: `lib/radiator/accounts/user.ex`
- Test: `test/radiator/accounts/user_test.exs`
- Create: `lib/radiator/accounts/user/calculations/display_name.ex`

**Interfaces:**
- Produces: Attribute `handle :: String.t()|nil` (unique), `avatar_url :: String.t()|nil`, `person_id :: uuid|nil`; `belongs_to :person`; `many_to_many :episodes`; Identity `:unique_handle`; Calc `:display_name`; Actions `:invite_by_email` (accept `[:email, :handle]`, passwortlos) und `:update_profile` (accept `[:handle, :avatar_url, :person_id]`).

- [ ] **Step 1: Failing test** — `test/radiator/accounts/user_test.exs`:

```elixir
defmodule Radiator.Accounts.UserTest do
  use Radiator.DataCase, async: true
  alias Radiator.Accounts.User

  test "invite_by_email creates a passwordless user" do
    user =
      User
      |> Ash.Changeset.for_create(:invite_by_email, %{email: "guest@example.com"}, authorize?: false)
      |> Ash.create!()

    assert to_string(user.email) == "guest@example.com"
    assert is_nil(user.hashed_password)
  end

  test "display_name falls back handle -> email and prefers linked person" do
    person =
      Radiator.People.create_person!(%{first_name: "Harald", last_name: "Lesch", display_name: "Harald Lesch"})

    user =
      User
      |> Ash.Changeset.for_create(:invite_by_email, %{email: "h@example.com", handle: "harry"}, authorize?: false)
      |> Ash.create!()
      |> Ash.Changeset.for_update(:update_profile, %{person_id: person.id}, authorize?: false)
      |> Ash.update!()
      |> Ash.load!(:display_name, authorize?: false)

    assert user.display_name == "Harald Lesch"
  end
end
```

- [ ] **Step 2: Test ausführen** — `mix test test/radiator/accounts/user_test.exs` → FAIL.

- [ ] **Step 3: Attribute** — in `user.ex` `attributes` ergänzen:

```elixir
    attribute :handle, :string, public?: true
    attribute :avatar_url, :string, public?: true
    attribute :person_id, :uuid, public?: true, allow_nil?: true
```

- [ ] **Step 4: Relationships** — `relationships`-Block ergänzen/anlegen:

```elixir
  relationships do
    belongs_to :person, Radiator.People.Person do
      allow_nil? true
      define_attribute? false
      public? true
    end

    many_to_many :episodes, Radiator.Podcasts.Episode do
      through Radiator.Podcasts.EpisodeParticipant
      public? true
    end
  end
```

- [ ] **Step 5: Identity** — in `identities` ergänzen: `identity :unique_handle, [:handle]`.

- [ ] **Step 6: Actions** — in `actions` ergänzen:

```elixir
    create :invite_by_email do
      description "Create a passwordless user to be invited as a voting participant."
      accept [:email, :handle]
    end

    update :update_profile do
      description "Update pseudonymous profile fields and optional person link."
      accept [:handle, :avatar_url, :person_id]
    end
```

- [ ] **Step 7: Policies** — `policies`-Block um die neuen Actions erweitern (grobgranular, da das Projekt noch kein Authz-Modell hat — später verfeinern):

```elixir
    policy action([:invite_by_email, :update_profile, :read]) do
      authorize_if always()
    end
```

- [ ] **Step 8: Calculation** — `lib/radiator/accounts/user/calculations/display_name.ex`:

```elixir
defmodule Radiator.Accounts.User.Calculations.DisplayName do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [:person]

  @impl true
  def calculate(users, _opts, _context) do
    Enum.map(users, fn user ->
      cond do
        match?(%{display_name: d} when is_binary(d) and d != "", user.person) -> user.person.display_name
        is_binary(user.handle) and user.handle != "" -> user.handle
        true -> to_string(user.email)
      end
    end)
  end
end
```

In `user.ex` einen `calculations`-Block ergänzen:

```elixir
  calculations do
    calculate :display_name, :string, Radiator.Accounts.User.Calculations.DisplayName
  end
```

- [ ] **Step 9: Migration + Test grün** — `mix ash.codegen user_profile_fields`; dann `mix test test/radiator/accounts/user_test.exs` → PASS. `mix compile --warnings-as-errors`.

- [ ] **Step 10: Commit**

```bash
git add lib/radiator/accounts test/radiator/accounts priv/repo/migrations priv/resource_snapshots
git commit -m "feat(accounts): pseudonymous User fields, person link, invite/profile actions, display_name"
```

---

## Phase B — People

### Task 3: Person neu modellieren + Persona-Beziehungen entfernen

**Files:**
- Modify: `lib/radiator/people/person.ex`
- Modify: `lib/radiator/people.ex`

**Interfaces:**
- Produces: `Person` mit `first_name`, `last_name`, `display_name`, `homepage_url`, `wikipedia_url`, `bio`; `has_one :user`; `People.create_person!/1`-Bang-Variante verfügbar.

- [ ] **Step 1: Person-Attribute ersetzen** — `lib/radiator/people/person.ex` `attributes`-Block:

```elixir
  attributes do
    uuid_primary_key :id

    attribute :first_name, :string, allow_nil?: false, public?: true
    attribute :last_name, :string, allow_nil?: true, public?: true
    attribute :display_name, :string, allow_nil?: true, public?: true
    attribute :homepage_url, :string, allow_nil?: true, public?: true
    attribute :wikipedia_url, :string, allow_nil?: true, public?: true
    attribute :bio, :string, allow_nil?: true, public?: true

    timestamps()
  end
```

`@default_accept_attributes` auf `[:first_name, :last_name, :display_name, :homepage_url, :wikipedia_url, :bio]` setzen. `alias Radiator.People.Persona` (Z. 10) entfernen.

- [ ] **Step 2: Relationships ersetzen** — `relationships`-Block:

```elixir
  relationships do
    has_one :user, Radiator.Accounts.User do
      destination_attribute :person_id
      public? true
    end
  end
```

- [ ] **Step 3: People-Domain bereinigen** — `lib/radiator/people.ex`: den `Persona`-Resource-Block entfernen, beim Person-Resource eine Bang-Variante ergänzen:

```elixir
  resources do
    resource Radiator.People.Person do
      define :read_persons, action: :read
      define :create_person, action: :create
      define :create_person!, action: :create
    end
  end
```

- [ ] **Step 4: Migration** — `mix ash.codegen person_real_data` (alte Spalten `real_name, nickname, email, telephone` weg; neue Felder dazu). *(Datenübernahme für bestehende Personen → Task 14.)*

- [ ] **Step 5: Kompilieren** — `mix compile --warnings-as-errors` (Restfehler nur aus noch-Persona-referenzierenden Modulen — erwartet).

- [ ] **Step 6: Commit**

```bash
git add lib/radiator/people priv/repo/migrations priv/resource_snapshots
git commit -m "refactor(people): Person models a real, referenceable human; drop persona relationships"
```

---

## Phase C — Podcasts/Scheduling: persona → user (Renames)

### Task 4: EpisodeParticipant auf User

**Files:** Modify `lib/radiator/podcasts/episode_participant.ex`

- [ ] **Step 1:** `alias Radiator.People.Persona` → `alias Radiator.Accounts.User`; `belongs_to :persona, Persona` → `belongs_to :user, User do allow_nil? false end`; Identity `:one_persona_per_episode, [:episode_id, :persona_id]` → `:one_user_per_episode, [:episode_id, :user_id]`; `@moduledoc` anpassen.
- [ ] **Step 2:** `mix compile --warnings-as-errors` (Restfehler erwartet).
- [ ] **Step 3:** `mix ash.codegen episode_participant_user`.
- [ ] **Step 4: Commit** — `git commit -m "refactor(podcasts): EpisodeParticipant references User"`.

---

### Task 5: Scheduling-Resource umbenennen

**Files:** Modify `lib/radiator/podcasts/episode/scheduling.ex`

**Exakte Ersetzungstabelle** (alle Vorkommen in der Datei):

| alt | neu |
|---|---|
| `reference :owner_persona` (Z. 33) | `reference :owner_user` |
| `owner_persona_id` | `owner_user_id` |
| `participant_persona_ids` | `participant_user_ids` |
| `created_by_persona_id` (Z. 68) | `created_by_user_id` |
| `argument :persona_id, :uuid` (alle Actions) | `argument :user_id, :uuid` |
| Variable `persona_id` + Verwendungen | `user_id` |
| `&(&1.persona_id == persona_id)` (Z. 176, 221) | `&(&1.user_id == user_id)` |
| `%{persona_id: persona_id, …}` (Z. 179) | `%{user_id: user_id, …}` |
| `belongs_to :owner_persona, Radiator.People.Persona` (Z. 353) | `belongs_to :owner_user, Radiator.Accounts.User` |
| `get_persona_votes/2` (Z. 410) | `get_user_votes/2` |
| `get_voted_personas/1` (Z. 501) | `get_voted_user_ids/1` |
| `MapSet.new(votes, & &1.persona_id)` (Z. 473) | `& &1.user_id` |
| `validate PersonaBelongsToActor` (Z. 159) | `validate UserIsActor` |
| `alias …Validations.PersonaBelongsToActor` (Z. 21) | `alias …Validations.UserIsActor` |

Code-Interface (Z. 37–42):

```elixir
  code_interface do
    define :get_by_episode, args: [:episode_id], action: :by_episode
    define :add_proposal, args: [:datetime, :user_id]
    define :vote, args: [:proposal_id, :user_id, :score]
    define :finalize, args: [:chosen_proposal_id, :user_id]
  end
```

`accept`-Listen in `:create`/`:create_with_proposals`: `:owner_persona_id, :participant_persona_ids` → `:owner_user_id, :participant_user_ids`.

- [ ] **Step 1:** Tabelle anwenden. **Step 2:** `mix compile --warnings-as-errors`. **Step 3:** `mix ash.codegen scheduling_user_columns`. **Step 4: Commit** — `git commit -m "refactor(scheduling): rename persona references to user"`.

---

### Task 6: Embedded Proposal & Vote

**Files:** Modify `proposal.ex`, `vote.ex`

- [ ] **Step 1: vote.ex** — `attribute :persona_id` → `:user_id` (Beschreibung „user who cast this vote"); `@moduledoc` anpassen.
- [ ] **Step 2: proposal.ex** — `created_by_persona_id` → `created_by_user_id` (Attribut + beide `accept`-Listen); Code-Interface `add_vote, args: [:user_id, :score]`, `remove_vote, args: [:user_id]`; Action-Argumente `:persona_id` → `:user_id`; `%Vote{persona_id: …}` → `%Vote{user_id: …}`; `&(&1.persona_id == …)` → `&(&1.user_id == …)`; Helper `get_vote_by_persona/2` → `get_vote_by_user/2`, `voted?/2` Param.
- [ ] **Step 3:** `mix compile --warnings-as-errors`.
- [ ] **Step 4: Commit** — `git commit -m "refactor(scheduling): embedded Proposal/Vote use user_id"`.

---

### Task 7: Validations

**Files:** `owner_only.ex`, `participant_only.ex`, `proposal_owner_or_creator.ex`; rename `persona_belongs_to_actor.ex` → `user_is_actor.ex`; Test umbenennen.

- [ ] **Step 1: OwnerOnly/ParticipantOnly/ProposalOwnerOrCreator** — `persona_id`→`user_id`, `owner_persona_id`→`owner_user_id`, `participant_persona_ids`→`participant_user_ids`, `proposal.created_by_persona_id`→`proposal.created_by_user_id`; `@moduledoc` anpassen.
- [ ] **Step 2: UserIsActor** — neue Datei `…/validations/user_is_actor.ex`:

```elixir
defmodule Radiator.Podcasts.Episode.Scheduling.Validations.UserIsActor do
  @moduledoc "Validates that the `user_id` argument equals the current actor's id."
  use Ash.Resource.Validation
  alias Radiator.Accounts.User

  @error_message "user does not match current actor"

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, context) do
    user_id = Ash.Changeset.get_argument(changeset, :user_id)

    case context.actor do
      %User{id: ^user_id} -> :ok
      _ -> {:error, field: :user_id, message: @error_message}
    end
  end
end
```

Alte Datei löschen; in `scheduling.ex` Alias/`validate` ist bereits in Task 5 umgestellt.

- [ ] **Step 3: Test** — `…/validations/persona_belongs_to_actor_test.exs` → `user_is_actor_test.exs`, Modul + Fälle auf `user_id`/`actor` umstellen (passt-wenn-`user_id==actor.id`, schlägt-fehl-bei-Mismatch, schlägt-fehl-ohne-actor).
- [ ] **Step 4: Test grün** — `mix test test/radiator/podcasts/episode/scheduling/validations/user_is_actor_test.exs`.
- [ ] **Step 5: Commit**

```bash
git add lib/radiator/podcasts/episode/scheduling/validations test/radiator/podcasts/episode/scheduling/validations
git rm lib/radiator/podcasts/episode/scheduling/validations/persona_belongs_to_actor.ex test/radiator/podcasts/episode/scheduling/validations/persona_belongs_to_actor_test.exs
git commit -m "refactor(scheduling): validations operate on user_id; UserIsActor"
```

---

### Task 8: Podcasts-Helper – Teilnehmer-Suche über User (inkl. Person-Felder)

**Files:** Modify `lib/radiator/podcasts.ex`

**Interfaces:**
- Produces: `read_podcast_participants/1 :: [%User{}]`; neuer `search_users/1 :: [%User{}]` (für Such-/Verbinden-UI; matched `handle`, `email`, und verknüpfte `person.first_name/last_name/display_name`).

- [ ] **Step 1:** `alias Radiator.People.Persona` → `alias Radiator.Accounts.User`; Funktion:

```elixir
  def read_podcast_participants(podcast_id) do
    User
    |> Ash.Query.filter(exists(episodes, podcast_id == ^podcast_id))
    |> Ash.Query.load([:display_name])
    |> Ash.read!(authorize?: false)
  end

  def search_users(term) when is_binary(term) do
    like = "%#{term}%"

    User
    |> Ash.Query.filter(
      ilike(handle, ^like) or ilike(type(email, :string), ^like) or
        ilike(person.first_name, ^like) or ilike(person.last_name, ^like) or
        ilike(person.display_name, ^like)
    )
    |> Ash.Query.load([:display_name])
    |> Ash.read!(authorize?: false)
  end
```

> `ilike`/`type` ggf. an die in diesem Projekt verfügbaren Ash-Expr-Funktionen anpassen (siehe `query_filter`-Referenz der ash-framework-Skill).

- [ ] **Step 2:** `mix compile --warnings-as-errors`.
- [ ] **Step 3: Commit** — `git commit -m "refactor(podcasts): participant helpers return Users; add user search"`.

---

## Phase D — Teilnehmer-Auflösung & Einladung

### Task 9: Episode – Teilnehmer per handle/email auflösen, unbekannte anlegen

**Files:** Modify `lib/radiator/podcasts/episode.ex`

**Interfaces:**
- Consumes: `User.:invite_by_email`, Identities `:handle`/`:unique_email`.
- Produces: `Episode.participants :: many_to_many User`; `:create`/`:update` verknüpfen bestehende User (per handle/email) und legen unbekannte E-Mails via `:invite_by_email` an.

- [ ] **Step 1:** `alias Radiator.People.Persona` → `alias Radiator.Accounts.User`; `many_to_many :participants, Persona` → `many_to_many :participants, User`.
- [ ] **Step 2: manage_relationship (create + update)** — in beiden Actions:

```elixir
      change manage_relationship(:participants,
               use_identities: [:handle, :unique_email],
               on_no_match: {:create, :invite_by_email},
               on_match: :ignore,
               on_lookup: :relate,
               on_missing: :unrelate
             )
```

> Jede Teilnehmer-Map enthält `%{email: "..."}` und/oder `%{handle: "..."}`. Vorhandene (per handle/email) werden verknüpft; eine unbekannte E-Mail erzeugt einen passwortlosen User (`:invite_by_email`).

- [ ] **Step 3: add/remove_participant** — `instance_of: Persona` → `instance_of: User` (Z. 82, 85–87).
- [ ] **Step 4:** `mix compile --warnings-as-errors`.
- [ ] **Step 5: Commit** — `git commit -m "feat(podcasts): resolve episode participants by handle/email; invite unknown emails"`.

---

### Task 10: Einladungs-Versand nach Speichern

**Files:**
- Modify: `lib/radiator/podcasts.ex`
- Test: `test/radiator/podcasts/invitations_test.exs`

**Interfaces:**
- Produces: `Podcasts.invite_new_participants/1` — nimmt eine Episode, ermittelt deren noch nicht onboardeten Teilnehmer (`hashed_password == nil and confirmed_at == nil`) und verschickt je einen Magic-Link-Deep-Link auf die Abstimmungsseite (Logik aus Task 11). Gibt `{:ok, [user]}` (eingeladene User) zurück.

- [ ] **Step 1: Failing test** — `test/radiator/podcasts/invitations_test.exs`: Episode mit neuer Teilnehmer-E-Mail anlegen, `invite_new_participants/1` aufrufen, prüfen dass genau dieser User in der Rückgabe ist und eine Mail versendet wurde (`assert_email_sent` via `Swoosh.TestAssertions`).

- [ ] **Step 2:** `mix test test/radiator/podcasts/invitations_test.exs` → FAIL.

- [ ] **Step 3: Implementieren** — in `lib/radiator/podcasts.ex`:

```elixir
  alias Radiator.Accounts.User

  @doc """
  Lädt alle noch nicht onboardeten Teilnehmer der Episode per Magic-Link
  zur Abstimmung ein (Deep-Link auf die Episode). Liefert die eingeladenen User.
  """
  def invite_new_participants(%{id: _} = episode) do
    episode = Ash.load!(episode, [:participants], authorize?: false)

    invited =
      Enum.filter(episode.participants, fn u ->
        is_nil(u.hashed_password) and is_nil(u.confirmed_at)
      end)

    Enum.each(invited, fn user ->
      Radiator.Accounts.send_voting_invitation(user, episode)
    end)

    {:ok, invited}
  end
```

> `Radiator.Accounts.send_voting_invitation/2` wird in Task 11 implementiert (Magic-Link-Token + Deep-Link-Mail). Test in Step 1 ggf. zunächst gegen einen einfachen Stub schreiben, der in Task 11 vervollständigt wird.

- [ ] **Step 4: Test grün** — nach Task 11. **Step 5: Commit** — `git commit -m "feat(podcasts): invite_new_participants sends voting invitations"`.

---

### Task 11: Magic-Link → Login als erzeugter User → Deep-Link zur Abstimmung

**Files:**
- Modify: `lib/radiator/accounts.ex` (Domain-Funktion + Code-Interface)
- Modify: `lib/radiator/accounts/user/senders/send_magic_link.ex` (oder separater Invitation-Sender)
- Modify: AuthController (vom Igniter generiert, z. B. `lib/radiator_web/controllers/auth_controller.ex`) für `return_to`-Redirect
- Test: erweitert `test/radiator/podcasts/invitations_test.exs`

**Interfaces:**
- Produces: `Radiator.Accounts.send_voting_invitation(user, episode)` — erzeugt einen Magic-Link-Token für `user`, baut eine URL, die (a) per Magic-Link genau diesen User einloggt und (b) anschließend zur Abstimmungsseite `~p"/admin/podcasts/#{podcast}/episodes/#{episode}"` weiterleitet, und versendet die „hier kannst du abstimmen"-Mail.

- [ ] **Step 1: Token-Erzeugung klären** — In der vom Igniter (Task 1) generierten Magic-Link-Integration nachsehen, wie ein Magic-Link-Token für einen bestehenden User erzeugt wird (i. d. R. über die `:request_magic_link`-Action bzw. `AshAuthentication.Strategy.MagicLink`). Den exakten Weg dieser Version notieren. Ziel: Token für `user.email` erzeugen.

- [ ] **Step 2: Deep-Link-Mechanik** — Zwei Bausteine:
  1. **Sign-in-URL mit `return_to`**: URL der Form
     `url(~p"/auth/user/magic_link?token=#{token}")` plus ein `return_to`-Query-Param mit dem Episode-Pfad. Falls die generierte Magic-Link-Route `return_to` nicht selbst auswertet, im **AuthController** im `success/4`-Callback auf den in `params`/Session übergebenen `return_to`-Pfad weiterleiten (sonst Default-Pfad). Beispiel:

```elixir
  # in AuthController.success/4
  def success(conn, _activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> redirect(to: return_to)
  end
```

  2. **`return_to` setzen**: Da die Mail-URL direkt zur Magic-Link-Route führt, den Episode-Pfad als Query-Param (`?token=…&return_to=/admin/...`) mitgeben und in einem kleinen Plug/in der Magic-Link-LiveView in die Session schreiben, bevor `success/4` läuft. **Diese Verdrahtung gegen die generierte ash_authentication_phoenix-Version verifizieren** (Skill `phoenix-framework`).

- [ ] **Step 3: Domain-Funktion + Sender** — in `lib/radiator/accounts.ex`:

```elixir
  def send_voting_invitation(user, episode) do
    Radiator.Accounts.User.Senders.SendVotingInvitation.send(user, episode)
  end
```

Sender `lib/radiator/accounts/user/senders/send_voting_invitation.ex` baut Token (Step 1) + Deep-Link-URL (Step 2), Subject „Hier kannst du abstimmen", Link → Magic-Link mit `return_to` = Episode-Show-Pfad. (Muster: `SendMagicLink`.)

- [ ] **Step 4: Test grün** — `mix test test/radiator/podcasts/invitations_test.exs` → PASS (Mail an die neue E-Mail versendet, Link enthält Token + Episode-Pfad).

- [ ] **Step 5: Commit** — `git commit -m "feat(accounts): magic-link voting invitation deep-links to episode"`.

---

## Phase E — Web-Layer

### Task 12: FormLive, ShowLive, AvailabilityHelpers, HEEx

**Files:** `form_live.ex`, `show_live.ex`, `availability_helpers.ex`, `form_live.html.heex`, `show_live.html.heex`

- [ ] **Step 1: FormLive** — `alias Radiator.People.Persona` → `alias Radiator.Accounts.User`.
  - Persona-Lookup entfällt: `:current_persona`-Assigns → vorhandenes `socket.assigns.current_user` nutzen.
  - `add_proposal`-Handler: `socket.assigns.current_persona` → `socket.assigns.current_user`; `created_by_persona_id`/`owner_persona_id` → `created_by_user_id`/`owner_user_id`.
  - Teilnehmer-Eingabe: das per `connect_participant`/`participants` gesammelte Map-Format auf `%{email: ...}` und/oder `%{handle: ...}` umstellen (Felder im Formular: E-Mail **und** optional Handle). `assign_candicates` nutzt `Podcasts.read_podcast_participants/1` bzw. `Podcasts.search_users/1`.
  - **`save`-Handler**: nach erfolgreichem `Form.submit` → `Podcasts.invite_new_participants(episode)` aufrufen und Flash „Einladungen versendet" ergänzen. Flash-Text Z. 103 anpassen.
- [ ] **Step 2: ShowLive** — `Persona` → `User`; Persona-Lookup entfällt (`@current_user`); `vote`-Handler `user.id`; `load_scheduling_participants`: `participant_persona_ids` → `participant_user_ids`, `Persona` → `User`, `Ash.Query.load([:display_name])`, `Enum.sort_by(& &1.display_name)`.
- [ ] **Step 3: AvailabilityHelpers** — `participant?/2`: `participant_persona_ids` → `participant_user_ids`, Param `persona`→`user`; `vote_for_persona/2` → `vote_for_user/2` (`&1.persona_id` → `&1.user_id`); `can_vote?/2` Param.
- [ ] **Step 4: HEEx** — exakt:
  - `form_live.html.heex`: Z. 29 `owner_persona_id` → `owner_user_id`; Z. 38 `created_by_persona_id` → `created_by_user_id`; Teilnehmer-Inputs auf E-Mail/Handle; `candicate.public_name` → `candicate.display_name`, `candicate.handle` bleibt.
  - `show_live.html.heex`: `@current_persona` → `@current_user`; Schleifenvar `persona` → `user`; `persona.public_name` → `user.display_name`; `vote_for_persona(...)` → `vote_for_user(...)`; `can_vote?(..., @current_persona)` → `@current_user`; Z. 211 `participant.public_name (participant.handle)` → `participant.display_name (participant.handle)`.
- [ ] **Step 5:** `mix compile --warnings-as-errors`.
- [ ] **Step 6: Commit** — `git commit -m "refactor(web): episode LiveViews use users; invite participants on save"`.

---

## Phase F — Tests, Seeds, Cleanup

### Task 13: Generator, Tests, Seeds

**Files:** `test/support/generator.ex`; alle Test-Dateien mit `persona`; `priv/repo/seeds.exs`; löschen: `test/radiator/people/persona_test.exs`.

- [ ] **Step 1: Generator** — `persona/1` entfernen; `Persona`-Alias raus, `User`-Alias rein. `person/1` auf neue Felder (`first_name`, `last_name`, `display_name`, `homepage_url`, `wikipedia_url`, `bio`). Neue `user/1`-Generatorfunktion:

```elixir
  def user(attrs \\ %{}) do
    seq(:user, fn i ->
      person_id = Map.get(attrs, :person_id)

      User
      |> Ash.Changeset.for_create(:invite_by_email, %{
        email: Map.get(attrs, :email, "user#{i}@radiator.de"),
        handle: Map.get(attrs, :handle, "handle#{i}")
      }, authorize?: false)
      |> Ash.create!()
      |> then(fn u ->
        if person_id do
          u |> Ash.Changeset.for_update(:update_profile, %{person_id: person_id}, authorize?: false) |> Ash.update!()
        else
          u
        end
      end)
    end)
  end
```

> Wo Tests einen User mit Passwort-Login brauchen, weiterhin `register_with_password` nutzen (bestehende `build_user/0`-Helfer beibehalten/anpassen).

- [ ] **Step 2: Tests umstellen** — global: `generate(persona(...))` → `generate(user(...))`; `owner_persona_id:`→`owner_user_id:`; `participant_persona_ids:`→`participant_user_ids:`; `persona_id:`→`user_id:`; `persona.id`→`user.id`; `.public_name`→`.display_name`; `register_user_without_persona`→`register_user_without_profile`. Validation-Test ist in Task 7 erledigt.
- [ ] **Step 3:** `persona_test.exs` löschen (ersetzt durch `user_test.exs`).
- [ ] **Step 4: Seeds** — `priv/repo/seeds.exs` ohne Personas: Bob/Jim als User (mit Passwort) + optional verknüpfter Person; Owner + 5 Teilnehmer als User; `owner_user_id`/`participant_user_ids`/`cast_vote(user_id:, actor: user)`.
- [ ] **Step 5: Suite** — `mix test` (nach Task 14 DB-Reset). 
- [ ] **Step 6: Commit**

```bash
git add test priv/repo/seeds.exs
git rm test/radiator/people/persona_test.exs
git commit -m "test: migrate generators, tests and seeds from persona to user"
```

---

### Task 14: Persona-Resource löschen, Tabelle droppen, Daten

**Files:** delete `lib/radiator/people/persona.ex`; codegen-Drop; ggf. Daten-Migration.

- [ ] **Step 1:** `rg -i persona lib/ test/ priv/repo/seeds.exs` → keine Codereferenz mehr. Reste beheben.
- [ ] **Step 2:** `lib/radiator/people/persona.ex` löschen.
- [ ] **Step 3:** `mix ash.codegen drop_personas` (droppt `personas`, entfernt Snapshots).
- [ ] **Step 4: Daten (nur bei nicht-leerer DB)** — VOR den Struktur-Migrationen aus Phase C eine manuelle Migration, die `personas.user_id` auf die Ziel-Spalten/JSONB mappt (`owner_persona_id`, `participant_persona_ids`, `episode_participants.persona_id`, `proposals.created_by_persona_id`, `votes[].persona_id`). Personas ohne `user_id` (externe Gäste) sind nicht abbildbar → vorher User anlegen oder Einträge entfernen; dokumentieren.
  > **Dev-Empfehlung:** `mix ash.reset` (drop → create → migrate → neue Seeds). Manuelle SQL nur für erhaltenswerte Daten.
- [ ] **Step 5:** `mix ash.reset` (Dev), dann `mix test`.
- [ ] **Step 6: Commit**

```bash
git add -A
git rm lib/radiator/people/persona.ex
git commit -m "refactor(people): remove Persona resource and personas table"
```

- [ ] **Step 7: Abschluss** — `mix precommit` grün.

---

### Task 15 (optional, Folge-Cleanup)

- Acting-User aus `context.actor` ableiten statt `user_id`-Argument (entfernt `UserIsActor`; betrifft Code-Interfaces/Web/Seeds/Tests).
- `participant_user_ids` (Array) und `EpisodeParticipant` vereinheitlichen.
- Person als referenzierbare Entität im Episoden-/Show-Notes-Content verknüpfbar machen (z. B. „in dieser Folge erwähnt: Harald Lesch") — eigenständiges Feature.
- User-Policies verfeinern (statt `authorize_if always()` für `:invite_by_email`/`:update_profile`).

---

## Self-Review

**Spec coverage:** User-Auth/Felder (T1–T2), Person (T3), EpisodeParticipant (T4), Scheduling (T5), Proposal/Vote (T6), Validations (T7), Podcasts-Helper (T8), Teilnehmer-Auflösung (T9), Einladung+Magic-Link-Deep-Link (T10–T11), Web (T12), Tests/Seeds (T13), Persona-Löschung+Daten (T14). ✓
Flow „Episode anlegen → unbekannte E-Mails als User → Mail mit Abstimmungs-Link → Login als dieser User → direkt zur Abstimmung": T1 (Strategy/passwortlos), T9 (Anlegen beim Speichern), T10 (Versand nach Speichern), T11 (Deep-Link-Login). ✓

**Placeholder-Scan:** Drei bewusst als „gegen generierten Code verifizieren" markierte Stellen (Magic-Link-Routen T1, Token-Erzeugung T11/Step 1, `return_to`-Redirect T11/Step 2) — kein TODO-Code, sondern Verifikationspunkte mit konkretem Lösungsweg + Skill-Verweis. Restlicher Code konkret.

**Typ-Konsistenz:** `user_id` durchgängig (Scheduling-Args, Vote, Proposal, Validations, Helper). Renames konsistent: `get_user_votes`, `get_voted_user_ids`, `vote_for_user`, `get_vote_by_user`. Relationship `owner_user` ↔ `owner_user_id`; `EpisodeParticipant.:user`; `User.display_name` (calc) in Web/Helper genutzt. `Podcasts.invite_new_participants/1` ↔ `Accounts.send_voting_invitation/2`.
