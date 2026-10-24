defmodule Radiator.Podcasts.Episode.Scheduling do
  @moduledoc """
  The search for an episode's recording date, Doodle-style.

  A podcast member starts it with one or more proposed dates. The episode's
  contributors with an account mark each proposal yes (`1`), maybe (`0`) or
  no (`-1`) and may propose further dates. A member finally picks one: the
  scheduling closes and the episode becomes `:scheduled`. Reopening undoes
  both and keeps every proposal and vote.

  Proposals and their votes are embedded; every change reads the list,
  changes it and writes it back (see `Proposals`). See
  `docs/specs/episode-scheduling/` and ADR 0001.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer,
    fragments: [Radiator.Podcasts.Episode.Scheduling.Policies]

  alias Radiator.Podcasts.Episode.Scheduling.Changes
  alias Radiator.Podcasts.Episode.Scheduling.Proposal
  alias Radiator.Podcasts.Episode.Scheduling.Validations

  postgres do
    table "episode_schedulings"
    repo Radiator.Repo

    references do
      reference :episode, on_delete: :delete
      reference :created_by, on_delete: :nilify
    end
  end

  actions do
    defaults [:read, :destroy]

    read :by_episode do
      get? true
      argument :episode_id, :uuid, allow_nil?: false

      filter expr(episode_id == ^arg(:episode_id))
    end

    create :start do
      description "Start looking for a recording date with one or more proposals."
      accept [:episode_id]

      argument :proposed_datetimes, {:array, :utc_datetime} do
        allow_nil? false
        constraints min_length: 1
      end

      validate Validations.EpisodeInScheduling

      change relate_actor(:created_by)
      change Changes.BuildProposals
      change set_attribute(:status, :open)
      change set_attribute(:published_at, &DateTime.utc_now/0)
    end

    update :add_proposal do
      require_atomic? false
      accept []
      argument :datetime, :utc_datetime, allow_nil?: false

      validate attribute_equals(:status, :open), message: "is closed"
      validate Validations.NoDuplicateDatetime

      change Changes.AddProposal
    end

    update :remove_proposal do
      require_atomic? false
      accept []
      argument :proposal_id, :uuid, allow_nil?: false

      validate attribute_equals(:status, :open), message: "is closed"
      validate Validations.ProposalExists
      validate Validations.MemberOrProposalCreator

      change Changes.RemoveProposal
    end

    update :vote do
      description "Vote 1 (yes), 0 (maybe) or -1 (no); a second vote replaces the first."
      require_atomic? false
      accept []
      argument :proposal_id, :uuid, allow_nil?: false
      argument :score, :integer, allow_nil?: false, constraints: [min: -1, max: 1]
      argument :comment, :string

      validate attribute_equals(:status, :open), message: "is closed"
      validate Validations.ProposalExists

      change Changes.RecordVote
    end

    update :remove_vote do
      require_atomic? false
      accept []
      argument :proposal_id, :uuid, allow_nil?: false

      validate attribute_equals(:status, :open), message: "is closed"
      validate Validations.ProposalExists

      change {Changes.RecordVote, remove?: true}
    end

    update :finalize do
      description "Pick the recording date; closes the scheduling and schedules the episode."
      require_atomic? false
      accept []
      argument :chosen_proposal_id, :uuid, allow_nil?: false

      validate attribute_equals(:status, :open), message: "is closed already"
      validate {Validations.ProposalExists, argument: :chosen_proposal_id}

      change Changes.ChooseProposal
      change {Changes.TransitionEpisode, action: :finalize_scheduling}
    end

    update :reopen do
      description "Give up the chosen date; proposals and votes are kept."
      require_atomic? false
      accept []

      validate attribute_equals(:status, :closed), message: "is open"

      change set_attribute(:status, :open)
      change set_attribute(:chosen_proposal_id, nil)
      change set_attribute(:chosen_datetime, nil)
      change set_attribute(:finalized_at, nil)
      change {Changes.TransitionEpisode, action: :back_to_scheduling}
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :status, :atom do
      allow_nil? false
      public? true
      default :open
      constraints one_of: [:open, :closed]
    end

    attribute :proposals, {:array, Proposal}, allow_nil?: false, default: [], public?: true

    attribute :chosen_proposal_id, :uuid, public?: true
    attribute :chosen_datetime, :utc_datetime, public?: true
    attribute :published_at, :utc_datetime, public?: true
    attribute :finalized_at, :utc_datetime, public?: true

    timestamps()
  end

  relationships do
    belongs_to :episode, Radiator.Podcasts.Episode, allow_nil?: false, public?: true
    belongs_to :created_by, Radiator.Accounts.User, public?: true
  end

  identities do
    identity :unique_episode, [:episode_id], message: "already has a scheduling"
  end
end
