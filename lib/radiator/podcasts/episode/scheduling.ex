defmodule Radiator.Podcasts.Episode.Scheduling do
  @moduledoc """
  Module for scheduling podcast episodes. This resource manages the scheduling phase
  when an episode is being planned and participants vote on proposed dates.

  Workflow:
  1. Owner starts scheduling with proposed datetimes and list of participants
  2. Participants are notified and can vote on proposals (`-1` no, `0` maybe, `1` yes)
  3. Participants can add new datetime proposals
  4. Owner monitors votes and decides on final datetime
  5. Owner finalizes scheduling, closing the vote and setting the chosen datetime
  """
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Podcasts.Episode.Scheduling.Proposal
  alias Radiator.Podcasts.Episode.Scheduling.Validations.OwnerOnly
  alias Radiator.Podcasts.Episode.Scheduling.Validations.ParticipantOnly
  alias Radiator.Podcasts.Episode.Scheduling.Validations.PersonaBelongsToActor
  alias Radiator.Podcasts.Episode.Scheduling.Validations.ProposalExists
  alias Radiator.Podcasts.Episode.Scheduling.Validations.ProposalOwnerOrCreator
  alias Radiator.Podcasts.Episode.Scheduling.Validations.ProposedDatetimesPresent
  alias Radiator.Podcasts.Episode.Scheduling.Validations.ValidScore

  postgres do
    table "episode_scheduling"
    repo Radiator.Repo

    references do
      reference :episode, on_delete: :delete
      reference :owner_persona, on_delete: :restrict
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
      validate ProposedDatetimesPresent

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

      validate attribute_equals(:status, :open) do
        message "Cannot add proposals to a closed scheduling"
      end

      validate {ParticipantOnly, message: "Only participants can add proposals"}

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

      validate attribute_equals(:status, :open) do
        message "Cannot remove proposals from a closed scheduling"
      end

      validate ProposalOwnerOrCreator

      change fn changeset, _context ->
        proposal_id = Ash.Changeset.get_argument(changeset, :proposal_id)
        existing_proposals = Ash.Changeset.get_attribute(changeset, :proposals) || []
        updated_proposals = Enum.reject(existing_proposals, &(&1.id == proposal_id))
        Ash.Changeset.change_attribute(changeset, :proposals, updated_proposals)
      end
    end

    update :vote do
      description "Vote on a proposal with a score of -1 (no), 0 (maybe) or 1 (yes)"
      require_atomic? false
      accept []
      argument :proposal_id, :uuid, allow_nil?: false
      argument :persona_id, :uuid, allow_nil?: false
      argument :score, :integer, allow_nil?: false
      argument :comment, :string, allow_nil?: true

      validate attribute_equals(:status, :open) do
        message "Cannot vote on a closed scheduling"
      end

      validate ValidScore
      validate {ParticipantOnly, message: "Only participants can vote"}
      validate PersonaBelongsToActor

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

      validate attribute_equals(:status, :open) do
        message "Cannot modify votes on a closed scheduling"
      end

      validate {ParticipantOnly, message: "Only participants can remove votes"}

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

      validate attribute_equals(:status, :open) do
        message "Scheduling is already closed"
      end

      validate {OwnerOnly, message: "Only the owner can finalize the scheduling"}
      validate ProposalExists

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

      validate attribute_equals(:status, :closed) do
        message "Scheduling must be closed to reopen"
      end

      validate {OwnerOnly, message: "Only the owner can reopen the scheduling"}

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

    belongs_to :owner_persona, Radiator.People.Persona do
      description "The persona who owns/created this scheduling"
      public? true
      allow_nil? false
    end
  end

  calculations do
    calculate :chosen_proposal, Proposal do
      description "The full chosen proposal struct (looked up from proposals list by chosen_proposal_id)"

      calculation fn records, _opts ->
        Enum.reduce(records, %{}, fn record, acc ->
          chosen =
            case record.chosen_proposal_id do
              nil ->
                nil

              id ->
                Enum.find(record.proposals || [], &(&1.id == id))
            end

          Map.put(acc, record.id, chosen)
        end)
      end
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
  Calculate voting statistics for the scheduling.

  Returns a map with status, aggregate counts across all proposals, the per-proposal
  statistics (sorted by `total_score` desc), and the top-level `top_proposal_id`
  (the proposal with the highest `total_score`, or `nil` on a tie).

  Per-proposal stats include `total_score`, `yes_count`, `maybe_count`, `no_count`,
  `pending_count` (participants without a vote on that proposal), and the raw
  `votes` list for UI rendering.
  """
  def voting_stats(scheduling) do
    participants = scheduling.participant_persona_ids || []
    proposals = scheduling.proposals || []
    proposal_stats = calculate_proposal_stats(proposals, participants)
    voted_personas = get_voted_personas(proposals)

    %{
      status: scheduling.status,
      participant_count: length(participants),
      proposal_count: length(proposals),
      total_votes: Enum.reduce(proposal_stats, 0, fn stat, acc -> acc + length(stat.votes) end),
      voted_participant_count: length(voted_personas),
      all_voted?: length(voted_personas) == length(participants),
      proposal_stats: proposal_stats,
      top_proposal: List.first(proposal_stats),
      top_proposal_id: determine_top_proposal_id(proposal_stats)
    }
  end

  @doc """
  Return the id of the proposal with the highest `total_score`.

  Returns `nil` when two or more proposals share the highest score (no unique
  winner) or when there are no proposals at all. Consistent with the
  `top_proposal_id` field returned by `voting_stats/1`.
  """
  def top_proposal_id(scheduling) do
    participants = scheduling.participant_persona_ids || []
    proposals = scheduling.proposals || []

    proposals
    |> calculate_proposal_stats(participants)
    |> determine_top_proposal_id()
  end

  defp calculate_proposal_stats(proposals, participants) do
    proposals
    |> Enum.map(&build_proposal_stat(&1, participants))
    |> Enum.sort_by(& &1.total_score, :desc)
  end

  defp build_proposal_stat(proposal, participants) do
    votes = proposal.votes || []
    voted_ids = MapSet.new(votes, & &1.persona_id)

    pending_count =
      Enum.count(participants, fn persona_id -> not MapSet.member?(voted_ids, persona_id) end)

    %{
      proposal_id: proposal.id,
      datetime: proposal.datetime,
      total_score: Enum.reduce(votes, 0, fn vote, acc -> acc + vote.score end),
      yes_count: Enum.count(votes, &(&1.score == 1)),
      maybe_count: Enum.count(votes, &(&1.score == 0)),
      no_count: Enum.count(votes, &(&1.score == -1)),
      pending_count: pending_count,
      votes: votes
    }
  end

  defp determine_top_proposal_id([]), do: nil

  defp determine_top_proposal_id(proposal_stats) do
    max_score = proposal_stats |> Enum.map(& &1.total_score) |> Enum.max()

    case Enum.filter(proposal_stats, &(&1.total_score == max_score)) do
      [single] -> single.proposal_id
      _ -> nil
    end
  end

  defp get_voted_personas(proposals) do
    proposals
    |> Enum.flat_map(fn proposal -> proposal.votes || [] end)
    |> Enum.map(& &1.persona_id)
    |> Enum.uniq()
  end
end
