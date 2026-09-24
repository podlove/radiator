defmodule Radiator.Podcasts.Podcast.Policies do
  @moduledoc """
  Who may do what with a podcast.

  Everyone may read the public fields through `:public_read`; the primary
  `:read` and every update or destroy are for its members only, and signed-in
  users may create. The sync machinery (`:sync`, `:mark_sync_failed`) runs from
  the Oban worker without an actor, so AshOban's interactions bypass both the
  owner check and the field policies; the check is only ever true for calls
  made by `ash_oban` itself.
  """

  use Spark.Dsl.Fragment, of: Ash.Resource, authorizers: [Ash.Policy.Authorizer]

  policies do
    bypass AshOban.Checks.AshObanInteraction do
      authorize_if always()
    end

    policy action(:read) do
      authorize_if relates_to_actor_via(:users)
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:users)
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:users)
    end

    policy action(:public_read) do
      authorize_if always()
    end
  end

  field_policies do
    private_fields :include

    field_policy_bypass :* do
      authorize_if AshOban.Checks.AshObanInteraction
    end

    field_policy_bypass [
      :title,
      :subtitle,
      :summary,
      :image_url,
      :episode_count,
      :latest_episode_at
    ] do
      authorize_if always()
    end

    field_policy :* do
      authorize_if relates_to_actor_via(:users)
    end
  end
end
