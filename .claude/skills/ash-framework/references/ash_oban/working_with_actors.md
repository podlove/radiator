# Working with Actors

AshOban can persist the actor that triggered a job, making it available when the job runs:

## Setting up Actor Persistence

```elixir
# Define an actor persister module
defmodule MyApp.ObanActorPersister do
  @behaviour AshOban.PersistActor

  @impl true
  def store(actor) do
    # Convert actor to a format that can be stored in JSON
    Jason.encode!(actor)
  end

  @impl true
  def lookup(actor_json) do
    # Convert the stored JSON back to an actor
    case Jason.decode(actor_json) do
      {:ok, data} -> {:ok, MyApp.Accounts.get_user!(data["id"])}
      error -> error
    end
  end
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
