defmodule Radiator.Podcasts.Episode.Scheduling.Vote do
  @moduledoc """
  Embedded resource representing a single vote from a user on a proposed datetime.

  Score model:

      -1 = no   (cannot attend)
       0 = maybe (unsure / tentative)
       1 = yes   (can attend)

  Keine Stimme im `votes`-Array bedeutet "noch nicht abgestimmt"
  und wird NICHT als 0 mitgerechnet.
  """

  use Ash.Resource,
    data_layer: :embedded

  actions do
    defaults [:read, :create, :update, :destroy]
  end

  attributes do
    attribute :user_id, :uuid do
      description "The user who cast this vote"
      allow_nil? false
      public? true
    end

    attribute :score, :integer do
      description "The vote score: -1 = no, 0 = maybe, 1 = yes"
      allow_nil? false
      public? true
      # Equivalent to `one_of: [-1, 0, 1]`; `Ash.Type.Integer` only supports
      # `:min` / `:max` constraints. The full whitelist is enforced by the
      # `ValidScore` action validation.
      constraints min: -1, max: 1
    end

    attribute :voted_at, :utc_datetime do
      description "When the vote was cast"
      allow_nil? false
      public? true
      default &DateTime.utc_now/0
    end

    attribute :comment, :string do
      description "Optional comment from the voter"
      allow_nil? true
      public? true
    end
  end
end
