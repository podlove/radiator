defmodule Radiator.Podcasts.Podcast.Policies do
  @moduledoc """
  Who may do what with a podcast.

  Everyone may read, signed-in users may create, and only the owner may update
  or destroy. The sync machinery (`:sync`, `:mark_sync_failed`) runs from the
  Oban worker without an actor, so AshOban's interactions bypass the owner
  check; the check is only ever true for calls made by `ash_oban` itself.
  """

  use Spark.Dsl.Fragment, of: Ash.Resource, authorizers: [Ash.Policy.Authorizer]

  policies do
    bypass AshOban.Checks.AshObanInteraction do
      authorize_if always()
    end

    policy action(:read) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action(:public_read) do
      authorize_if always()
    end
  end

  field_policies do
    private_fields :include

    field_policy_bypass [:title, :subtitle, :summary, :image_url] do
      authorize_if always()
    end

    field_policy :* do
      authorize_if relates_to_actor_via(:user)
    end
  end
end
