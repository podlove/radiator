defmodule Radiator.Podcasts.Episode.Scheduling.Proposal do
  @moduledoc """
  A proposed recording date and the votes cast on it.

  Proposals live embedded in their scheduling; they are only ever changed
  through the scheduling's actions.
  """

  use Ash.Resource, data_layer: :embedded

  alias Radiator.Podcasts.Episode.Scheduling.Vote

  attributes do
    attribute :id, :uuid do
      primary_key? true
      allow_nil? false
      public? true
      default &Ash.UUID.generate/0
    end

    attribute :datetime, :utc_datetime do
      description "The proposed start of the recording, in UTC"
      allow_nil? false
      public? true
    end

    attribute :created_by_user_id, :uuid do
      description "The user who proposed the date"
      public? true
    end

    attribute :votes, {:array, Vote}, allow_nil?: false, default: [], public?: true

    attribute :inserted_at, :utc_datetime do
      public? true
      default &DateTime.utc_now/0
    end
  end

  @doc "The vote of `person_id` on this proposal, or `nil` while they are pending."
  def vote_by_person(%__MODULE__{votes: votes}, person_id),
    do: Enum.find(votes || [], &(&1.person_id == person_id))
end
