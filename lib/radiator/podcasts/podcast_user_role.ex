defmodule Radiator.Podcasts.PodcastUserRole do
  @moduledoc """
  A user's membership in a podcast, and the role they hold there.

  Memberships are only managed through the podcast (`:update` with its
  `memberships` argument), hence the `accessing_from/2` policies. Nobody may
  remove their own membership or change its role; the podcast makes sure an owner remains.

  A new membership is created from an email address: the user is looked up
  and created if they do not exist yet.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Podcast

  postgres do
    table "podcast_user_roles"
    repo Radiator.Repo

    references do
      reference :podcast, on_delete: :delete, index?: true
      reference :user, on_delete: :delete, index?: true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:role, :user_id, :podcast_id]
      # Filled in from `email` right before the insert.
      allow_nil_input [:user_id]

      argument :email, :ci_string

      validate present([:email, :user_id], at_least: 1), message: "is required"

      validate match(:email, ~r/^[^\s@]+@[^\s@]+$/),
        where: present(:email),
        message: "must be an email address"

      change Radiator.Podcasts.PodcastUserRole.Changes.ResolveUser
    end

    update :update do
      primary? true
      accept [:role]
      # The check compares against the stored membership.
      require_atomic? false

      validate Radiator.Podcasts.PodcastUserRole.Validations.OwnRoleUnchanged
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if accessing_from(Podcast, :memberships)
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type([:create, :update]) do
      authorize_if accessing_from(Podcast, :memberships)
    end

    policy action_type(:destroy) do
      forbid_if expr(user_id == ^actor(:id))
      authorize_if accessing_from(Podcast, :memberships)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, Radiator.Podcasts.PodcastRole do
      allow_nil? false
      default :owner
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :podcast, Podcast, allow_nil?: false
    belongs_to :user, User, allow_nil?: false, public?: true
  end

  identities do
    identity :unique_user_per_podcast, [:podcast_id, :user_id]
  end
end
