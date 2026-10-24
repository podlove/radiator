defmodule Radiator.Podcasts.Episode.Scheduling.Vote do
  @moduledoc """
  A contributor's availability for one proposed date.

      1 = yes   (can attend)
      0 = maybe (unsure)
     -1 = no    (cannot attend)

  A contributor without a vote on a proposal is *pending*; that is not the
  same as `0` and never counts as one.
  """

  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :person_id, :uuid do
      description "The contributor person who voted"
      allow_nil? false
      public? true
    end

    attribute :score, :integer do
      allow_nil? false
      public? true
      constraints min: -1, max: 1
    end

    attribute :voted_at, :utc_datetime do
      allow_nil? false
      public? true
      default &DateTime.utc_now/0
    end

    attribute :comment, :string, public?: true
  end
end
