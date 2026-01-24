defmodule Radiator.Podcasts.Episode.Scheduling.Vote do
  @moduledoc """
  Embedded resource representing a single vote from a persona on a proposed datetime.
  Uses a 5-point scoring system where:
  - 1 = Strongly disagree/Cannot attend
  - 2 = Disagree/Unlikely to attend
  - 3 = Neutral/Maybe can attend
  - 4 = Agree/Likely to attend
  - 5 = Strongly agree/Definitely can attend
  """

  use Ash.Resource,
    data_layer: :embedded

  actions do
    defaults [:read, :create, :update, :destroy]
  end

  attributes do
    attribute :persona_id, :uuid do
      description "The persona who cast this vote"
      allow_nil? false
      public? true
    end

    attribute :score, :integer do
      description "The vote score (1-5)"
      allow_nil? false
      public? true
      constraints min: 1, max: 5
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
