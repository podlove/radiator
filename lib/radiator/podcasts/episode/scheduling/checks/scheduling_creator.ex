defmodule Radiator.Podcasts.Episode.Scheduling.Checks.SchedulingCreator do
  @moduledoc "The actor started the scheduling (`created_by`)."

  use Ash.Policy.FilterCheck

  @impl true
  def describe(_opts), do: "actor started the scheduling"

  @impl true
  def filter(_actor, _authorizer, _opts), do: expr(created_by_id == ^actor(:id))
end
