defmodule Radiator.Podcasts.Episode.Scheduling.Proposal do
  @moduledoc """
  Embedded resource representing a proposed datetime for an episode scheduling.
  Contains the proposed datetime and all votes from participants.
  """

  use Ash.Resource,
    data_layer: :embedded

  alias Radiator.Podcasts.Episode.Scheduling.Vote

  code_interface do
    define :create
    define :update
    define :add_vote, args: [:persona_id, :score]
    define :remove_vote, args: [:persona_id]
  end

  actions do
    defaults [:read, :destroy, :update]

    create :create do
      primary? true
      accept [:id, :datetime, :created_by_persona_id, :votes, :inserted_at, :updated_at]
    end

    update :add_vote do
      accept []
      argument :persona_id, :uuid, allow_nil?: false
      argument :score, :integer, allow_nil?: false

      validate fn changeset, _context ->
        score = Ash.Changeset.get_argument(changeset, :score)

        if score in 1..5 do
          :ok
        else
          {:error, field: :score, message: "Score must be between 1 and 5"}
        end
      end

      change fn changeset, _context ->
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        score = Ash.Changeset.get_argument(changeset, :score)

        existing_votes = Ash.Changeset.get_attribute(changeset, :votes) || []

        # Remove any existing vote from this persona
        updated_votes =
          existing_votes
          |> Enum.reject(&(&1.persona_id == persona_id))
          |> then(fn votes ->
            [
              %Vote{
                persona_id: persona_id,
                score: score,
                voted_at: DateTime.utc_now()
              }
              | votes
            ]
          end)

        Ash.Changeset.change_attribute(changeset, :votes, updated_votes)
      end
    end

    update :remove_vote do
      accept []
      argument :persona_id, :uuid, allow_nil?: false

      change fn changeset, _context ->
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        existing_votes = Ash.Changeset.get_attribute(changeset, :votes) || []

        updated_votes = Enum.reject(existing_votes, &(&1.persona_id == persona_id))

        Ash.Changeset.change_attribute(changeset, :votes, updated_votes)
      end
    end
  end

  attributes do
    attribute :id, :uuid do
      primary_key? true
      allow_nil? false
      writable? true
      generated? false
      default &Ash.UUID.generate/0
      public? true
    end

    attribute :datetime, :utc_datetime do
      description "The proposed date and time for the episode"
      allow_nil? false
      public? true
    end

    attribute :created_by_persona_id, :uuid do
      description "The persona who created this proposal"
      allow_nil? false
      public? true
    end

    attribute :votes, {:array, Vote} do
      description "List of votes for this proposal"
      default []
      public? true
    end

    attribute :inserted_at, :utc_datetime do
      allow_nil? true
      public? true
      default fn -> DateTime.utc_now() |> DateTime.truncate(:second) end
    end

    attribute :updated_at, :utc_datetime do
      allow_nil? true
      public? true
      default fn -> DateTime.utc_now() |> DateTime.truncate(:second) end
    end
  end

  calculations do
    calculate :total_votes, :integer, expr(length(votes))

    calculate :average_score, :decimal do
      calculation fn records, _opts ->
        Enum.reduce(records, %{}, fn record, acc ->
          avg =
            case record.votes do
              [] ->
                nil

              votes ->
                sum = Enum.reduce(votes, 0, fn vote, sum -> sum + vote.score end)
                Decimal.div(sum, length(votes))
            end

          Map.put(acc, record.id, avg)
        end)
      end
    end
  end

  def get_vote_by_persona(proposal, persona_id) do
    Enum.find(proposal.votes || [], &(&1.persona_id == persona_id))
  end

  def voted?(proposal, persona_id) do
    Enum.any?(proposal.votes || [], &(&1.persona_id == persona_id))
  end

  def votes_count(proposal) do
    length(proposal.votes || [])
  end
end
