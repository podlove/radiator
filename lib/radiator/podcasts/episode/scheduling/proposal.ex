defmodule Radiator.Podcasts.Episode.Scheduling.Proposal do
  @moduledoc """
  Embedded resource representing a proposed datetime for an episode scheduling.
  Contains the proposed datetime and all votes from participants.
  """

  use Ash.Resource,
    data_layer: :embedded

  alias Radiator.Podcasts.Episode.Scheduling.Validations.ValidScore
  alias Radiator.Podcasts.Episode.Scheduling.Vote

  code_interface do
    define :create
    define :update
    define :add_vote, args: [:user_id, :score]
    define :remove_vote, args: [:user_id]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:id, :datetime, :created_by_user_id, :votes, :inserted_at, :updated_at]
    end

    update :update do
      primary? true
      accept [:datetime, :created_by_user_id, :votes]
    end

    update :add_vote do
      accept []
      argument :user_id, :uuid, allow_nil?: false
      argument :score, :integer, allow_nil?: false

      validate ValidScore

      change fn changeset, _context ->
        user_id = Ash.Changeset.get_argument(changeset, :user_id)
        score = Ash.Changeset.get_argument(changeset, :score)

        existing_votes = Ash.Changeset.get_attribute(changeset, :votes) || []

        # Remove any existing vote from this user
        updated_votes =
          existing_votes
          |> Enum.reject(&(&1.user_id == user_id))
          |> then(fn votes ->
            [
              %Vote{
                user_id: user_id,
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
      argument :user_id, :uuid, allow_nil?: false

      change fn changeset, _context ->
        user_id = Ash.Changeset.get_argument(changeset, :user_id)
        existing_votes = Ash.Changeset.get_attribute(changeset, :votes) || []

        updated_votes = Enum.reject(existing_votes, &(&1.user_id == user_id))

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

    attribute :created_by_user_id, :uuid do
      description "The user who created this proposal"
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

  def get_vote_by_user(proposal, user_id) do
    Enum.find(proposal.votes || [], &(&1.user_id == user_id))
  end

  def voted?(proposal, user_id) do
    Enum.any?(proposal.votes || [], &(&1.user_id == user_id))
  end

  def votes_count(proposal) do
    length(proposal.votes || [])
  end
end
