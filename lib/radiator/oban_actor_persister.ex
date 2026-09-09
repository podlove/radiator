defmodule Radiator.ObanActorPersister do
  @moduledoc """
  Stores and restores the actor of an Oban job.

  No policy depends on it yet; it is here because jobs already in the queue
  could not be retrofitted with the information later.
  """

  use AshOban.ActorPersister

  alias Radiator.Accounts.User

  @impl true
  def store(%User{id: id}), do: %{"type" => "user", "id" => id}
  def store(_actor), do: nil

  @impl true
  def lookup(nil), do: {:ok, nil}

  def lookup(%{"type" => "user", "id" => id}) do
    case Ash.get(User, id, authorize?: false) do
      {:ok, user} -> {:ok, user}
      # A deleted user must not wedge the queue.
      {:error, _error} -> {:ok, nil}
    end
  end

  def lookup(_other), do: {:ok, nil}
end
