defmodule Radiator.Podcasts.Episode.Scheduling do
  @moduledoc """
  Module for scheduling podcast episodes. This resource manages the scheduling phase
  when an episode is being planned and participants vote on proposed dates.

  Workflow:
  1. Owner starts scheduling with proposed datetimes and list of participants
  2. Participants are notified and can vote on proposals (1-5 score)
  3. Participants can add new datetime proposals
  4. Owner monitors votes and decides on final datetime
  5. Owner finalizes scheduling, closing the vote and setting the chosen datetime
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Podcasts.Episode.Scheduling.Proposal

  postgres do
    table "episode_scheduling"
    repo Radiator.Repo

    references do
      reference :episode, on_delete: :delete
    end
  end

  code_interface do
    define :get_by_episode, args: [:episode_id], action: :by_episode
    define :add_proposal, args: [:datetime, :persona_id]
    define :vote, args: [:proposal_id, :persona_id, :score]
    define :finalize, args: [:chosen_proposal_id, :persona_id]
  end

  actions do
    defaults [:read, :destroy]

    update :update do
      accept [:proposals]
      require_atomic? false
      primary? true
    end

    create :create do
      description "Start a new scheduling for an episode with initial proposals and participants"
      accept [:episode_id, :owner_persona_id, :participant_persona_ids, :proposals]
      argument :proposed_datetimes, {:array, :utc_datetime}, allow_nil?: false

      validate fn changeset, _context ->
        proposed_datetimes = Ash.Changeset.get_argument(changeset, :proposed_datetimes)

        if Enum.empty?(proposed_datetimes) do
          {:error,
           field: :proposed_datetimes, message: "At least one proposed datetime is required"}
        else
          :ok
        end
      end

      change fn changeset, _context ->
        proposed_datetimes = Ash.Changeset.get_argument(changeset, :proposed_datetimes)
        owner_persona_id = Ash.Changeset.get_attribute(changeset, :owner_persona_id)

        proposals =
          Enum.map(proposed_datetimes, fn datetime ->
            %{
              id: Ash.UUID.generate(),
              datetime: datetime,
              created_by_persona_id: owner_persona_id,
              votes: []
            }
          end)

        changeset
        |> Ash.Changeset.change_attribute(:proposals, proposals)
        |> Ash.Changeset.change_attribute(:status, :open)
        |> Ash.Changeset.change_attribute(:published_at, DateTime.utc_now())
      end
    end

    update :add_proposal do
      description "Add a new datetime proposal to the scheduling"
      require_atomic? false
      accept []
      argument :datetime, :utc_datetime, allow_nil?: false
      argument :persona_id, :uuid, allow_nil?: false

      validate fn changeset, _context ->
        status = Ash.Changeset.get_attribute(changeset, :status)

        if status == :open do
          :ok
        else
          {:error, message: "Cannot add proposals to a closed scheduling"}
        end
      end

      validate fn changeset, _context ->
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        participant_ids = Ash.Changeset.get_attribute(changeset, :participant_persona_ids) || []

        if persona_id in participant_ids do
          :ok
        else
          {:error, message: "Only participants can add proposals"}
        end
      end

      change fn changeset, _context ->
        datetime = Ash.Changeset.get_argument(changeset, :datetime)
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)

        existing_proposals =
          case Ash.Changeset.get_attribute(changeset, :proposals) do
            nil -> []
            proposals when is_list(proposals) -> proposals
            proposals when is_map(proposals) -> Map.values(proposals)
          end

        new_proposal = %{
          id: Ash.UUID.generate(),
          datetime: datetime,
          created_by_persona_id: persona_id,
          votes: []
        }

        Ash.Changeset.change_attribute(changeset, :proposals, [new_proposal | existing_proposals])
      end
    end

    update :remove_proposal do
      description "Remove a proposal from the scheduling"
      require_atomic? false
      accept []
      argument :proposal_id, :uuid, allow_nil?: false
      argument :persona_id, :uuid, allow_nil?: false

      validate fn changeset, _context ->
        status = Ash.Changeset.get_attribute(changeset, :status)

        if status == :open do
          :ok
        else
          {:error, message: "Cannot remove proposals from a closed scheduling"}
        end
      end

      validate fn changeset, _context ->
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        owner_id = Ash.Changeset.get_attribute(changeset, :owner_persona_id)
        proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)

        proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []
        proposal = Enum.find(proposals, &(&1.id == proposal_id))

        cond do
          is_nil(proposal) ->
            {:error, message: "Proposal not found"}

          persona_id == owner_id ->
            :ok

          proposal.created_by_persona_id == persona_id ->
            :ok

          true ->
            {:error, message: "Only the owner or proposal creator can remove proposals"}
        end
      end

      change fn changeset, _context ->
        proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)
        existing_proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []
        updated_proposals = Enum.reject(existing_proposals, &(&1.id == proposal_id))
        Ash.Changeset.change_attribute(changeset, :proposals, updated_proposals)
      end
    end

    update :vote do
      description "Vote on a proposal with a score from 1-5"
      require_atomic? false
      accept []
      argument :proposal_id, :uuid, allow_nil?: false
      argument :persona_id, :uuid, allow_nil?: false
      argument :score, :integer, allow_nil?: false
      argument :comment, :string, allow_nil?: true

      validate fn changeset, _context ->
        status = Ash.Changeset.get_attribute(changeset, :status)

        if status == :open do
          :ok
        else
          {:error, message: "Cannot vote on a closed scheduling"}
        end
      end

      validate fn changeset, _context ->
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        participant_ids = Ash.Changeset.get_attribute(changeset, :participant_persona_ids) || []

        if persona_id in participant_ids do
          :ok
        else
          {:error, message: "Only participants can vote"}
        end
      end

      validate fn changeset, _context ->
        score = Ash.Changeset.get_argument(changeset, :score)

        if score in 1..5 do
          :ok
        else
          {:error, field: :score, message: "Score must be between 1 and 5"}
        end
      end

      change fn changeset, _context ->
        proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        score = Ash.Changeset.get_argument(changeset, :score)
        comment = Ash.Changeset.get_argument(changeset, :comment)

        existing_proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []

        updated_proposals =
          Enum.map(existing_proposals, fn proposal ->
            if proposal.id == proposal_id do
              existing_votes = proposal.votes || []

              updated_votes =
                existing_votes
                |> Enum.reject(&(&1.persona_id == persona_id))
                |> then(fn votes ->
                  [
                    %{
                      persona_id: persona_id,
                      score: score,
                      comment: comment,
                      voted_at: DateTime.utc_now() |> DateTime.truncate(:second)
                    }
                    | votes
                  ]
                end)

              %{proposal | votes: updated_votes}
            else
              proposal
            end
          end)

        Ash.Changeset.change_attribute(changeset, :proposals, updated_proposals)
      end
    end

    update :remove_vote do
      description "Remove a vote from a proposal"
      require_atomic? false
      accept []
      argument :proposal_id, :uuid, allow_nil?: false
      argument :persona_id, :uuid, allow_nil?: false

      validate fn changeset, _context ->
        status = Ash.Changeset.get_attribute(changeset, :status)

        if status == :open do
          :ok
        else
          {:error, message: "Cannot modify votes on a closed scheduling"}
        end
      end

      change fn changeset, _context ->
        proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)

        existing_proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []

        updated_proposals =
          Enum.map(existing_proposals, fn proposal ->
            if proposal.id == proposal_id do
              updated_votes = Enum.reject(proposal.votes || [], &(&1.persona_id == persona_id))
              %{proposal | votes: updated_votes}
            else
              proposal
            end
          end)

        Ash.Changeset.change_attribute(changeset, :proposals, updated_proposals)
      end
    end

    update :finalize do
      description "Finalize the scheduling by choosing a proposal and closing the vote"
      require_atomic? false
      accept []
      argument :chosen_proposal_id, :uuid, allow_nil?: false
      argument :persona_id, :uuid, allow_nil?: false

      validate fn changeset, _context ->
        status = Ash.Changeset.get_attribute(changeset, :status)

        if status == :open do
          :ok
        else
          {:error, message: "Scheduling is already closed"}
        end
      end

      validate fn changeset, _context ->
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        owner_id = Ash.Changeset.get_attribute(changeset, :owner_persona_id)

        if persona_id == owner_id do
          :ok
        else
          {:error, message: "Only the owner can finalize the scheduling"}
        end
      end

      validate fn changeset, _context ->
        chosen_proposal_id = Ash.Changeset.get_argument(changeset, :chosen_proposal_id)
        existing_proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []

        if Enum.any?(existing_proposals, &(&1.id == chosen_proposal_id)) do
          :ok
        else
          {:error, message: "Chosen proposal not found"}
        end
      end

      change fn changeset, _context ->
        chosen_proposal_id = Ash.Changeset.get_argument(changeset, :chosen_proposal_id)
        proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []
        chosen_proposal = Enum.find(proposals, &(&1.id == chosen_proposal_id))

        case chosen_proposal do
          nil ->
            changeset

          proposal ->
            changeset
            |> Ash.Changeset.change_attribute(:status, :closed)
            |> Ash.Changeset.change_attribute(:chosen_proposal_id, chosen_proposal_id)
            |> Ash.Changeset.change_attribute(:chosen_datetime, proposal.datetime)
            |> Ash.Changeset.change_attribute(:finalized_at, DateTime.utc_now())
        end
      end
    end

    update :reopen do
      description "Reopen a closed scheduling"
      require_atomic? false
      accept []
      argument :persona_id, :uuid, allow_nil?: false

      validate fn changeset, _context ->
        persona_id = Ash.Changeset.get_argument(changeset, :persona_id)
        owner_id = Ash.Changeset.get_attribute(changeset, :owner_persona_id)

        if persona_id == owner_id do
          :ok
        else
          {:error, message: "Only the owner can reopen the scheduling"}
        end
      end

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:status, :open)
        |> Ash.Changeset.change_attribute(:chosen_proposal_id, nil)
        |> Ash.Changeset.change_attribute(:chosen_datetime, nil)
        |> Ash.Changeset.change_attribute(:finalized_at, nil)
      end
    end

    read :by_episode do
      description "Get scheduling by episode ID"
      argument :episode_id, :uuid, allow_nil?: false

      filter expr(episode_id == ^arg(:episode_id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :status, :atom do
      description "Status of the scheduling (open or closed)"
      allow_nil? false
      public? true
      default :open
      constraints one_of: [:open, :closed]
    end

    attribute :owner_persona_id, :uuid do
      description "The persona who owns/created this scheduling"
      allow_nil? false
      public? true
    end

    attribute :participant_persona_ids, {:array, :uuid} do
      description "List of persona IDs who can participate in voting"
      allow_nil? false
      public? true
      default []
    end

    attribute :proposals, {:array, Proposal} do
      description "List of proposed datetimes with their votes (stored as JSONB)"
      allow_nil? false
      public? true
      default []
    end

    attribute :chosen_proposal_id, :uuid do
      description "The ID of the chosen proposal (when finalized)"
      allow_nil? true
      public? true
    end

    attribute :chosen_datetime, :utc_datetime do
      description "The chosen datetime (when finalized)"
      allow_nil? true
      public? true
    end

    attribute :published_at, :utc_datetime do
      description "When the scheduling was published and made available for voting"
      allow_nil? true
      public? true
    end

    attribute :finalized_at, :utc_datetime do
      description "When the scheduling was finalized"
      allow_nil? true
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :episode, Radiator.Podcasts.Episode do
      description "The episode being scheduled"
      public? true
      allow_nil? false
    end
  end

  identities do
    identity :unique_episode, [:episode_id], message: "episode already has a scheduling"
  end

  # Helper functions

  @doc """
  Get a specific proposal by ID from a scheduling record
  """
  def get_proposal(scheduling, proposal_id) do
    Enum.find(scheduling.proposals || [], &(&1.id == proposal_id))
  end

  @doc """
  Check if a persona has voted on a specific proposal
  """
  def voted_on_proposal?(scheduling, proposal_id, persona_id) do
    case get_proposal(scheduling, proposal_id) do
      nil ->
        false

      proposal ->
        Enum.any?(proposal.votes || [], &(&1.persona_id == persona_id))
    end
  end

  @doc """
  Get all votes from a specific persona across all proposals
  """
  def get_persona_votes(scheduling, persona_id) do
    Enum.reduce(scheduling.proposals || [], [], fn proposal, acc ->
      case Enum.find(proposal.votes || [], &(&1.persona_id == persona_id)) do
        nil -> acc
        vote -> [{proposal.id, vote} | acc]
      end
    end)
  end

  @doc """
  Calculate voting statistics for the scheduling
  """
  def voting_stats(scheduling) do
    participant_count = length(scheduling.participant_persona_ids || [])
    proposal_count = length(scheduling.proposals || [])
    proposal_stats = calculate_proposal_stats(scheduling.proposals || [])
    voted_personas = get_voted_personas(scheduling.proposals || [])

    %{
      status: scheduling.status,
      participant_count: participant_count,
      proposal_count: proposal_count,
      total_votes: Enum.reduce(proposal_stats, 0, fn stat, acc -> acc + stat.vote_count end),
      voted_participant_count: length(voted_personas),
      all_voted?: length(voted_personas) == participant_count,
      proposal_stats: proposal_stats,
      top_proposal: List.first(proposal_stats)
    }
  end

  defp calculate_proposal_stats(proposals) do
    proposals
    |> Enum.map(&build_proposal_stat/1)
    |> Enum.sort(fn a, b ->
      case {a.average_score, b.average_score} do
        {nil, nil} -> true
        {nil, _} -> false
        {_, nil} -> true
        {a_score, b_score} -> a_score >= b_score
      end
    end)
  end

  defp build_proposal_stat(proposal) do
    votes = proposal.votes || []

    %{
      proposal_id: proposal.id,
      datetime: proposal.datetime,
      vote_count: length(votes),
      average_score: calculate_average_score(votes),
      votes: votes
    }
  end

  defp calculate_average_score([]), do: nil

  defp calculate_average_score(votes) do
    sum = Enum.reduce(votes, 0, fn vote, acc -> acc + vote.score end)
    Float.round(sum / length(votes), 2)
  end

  defp get_voted_personas(proposals) do
    proposals
    |> Enum.flat_map(fn proposal -> proposal.votes || [] end)
    |> Enum.map(& &1.persona_id)
    |> Enum.uniq()
  end
end
