# Working with Actors

AshOban can persist the actor that triggered a job, making it available when the job runs:

## Setting up Actor Persistence

```elixir
# Define an actor persister module
defmodule MyApp.ObanActorPersister do
  use AshOban.ActorPersister

  # Convert the actor to a value that can be stored in the job's JSON arguments
  @impl true
  def store(%MyApp.Accounts.User{id: id}), do: %{"type" => "user", "id" => id}

  # Convert the stored value back to an actor
  @impl true
  def lookup(%{"type" => "user", "id" => id}), do: MyApp.Accounts.get_user_by_id(id)

  # Jobs scheduled without an actor
  def lookup(nil), do: {:ok, nil}
end

# Configure it
config :ash_oban, :actor_persister, MyApp.ObanActorPersister
```

## Using Actor in Triggers

```elixir
# Specify actor_persister for a specific trigger
trigger :process do
  action :process
  actor_persister MyApp.ObanActorPersister
end

# Pass the actor when triggering a job
AshOban.run_trigger(record, :process, actor: current_user)
```
