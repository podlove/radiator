defmodule Radiator.Constants do
  @moduledoc false

  def permissions do
    quote do
      @permission_values [:readonly, :edit, :manage, :own]
      defguard is_permission(p) when p in @permission_values

      @type permission() :: :readonly | :edit | :manage | :own
      @type permission_subject() :: Podcast.t() | Network.t() | Episode.t() | AudioPublication.t()
    end
  end

  def general do
    quote do
      @otp_app Mix.Project.config()[:app]

      @auth_user_status_values [:unverified, :active, :suspended]

      @not_authorized_match {:error, :not_authorized}
      @not_authorized_response {:error, "Not Authorized"}

      @not_found_match {:error, :not_found}
      @not_found_response {:error, "Entity not found"}

      defguard is_user_status(s) when s in @auth_user_status_values
    end
  end

  @doc """
  When used, dispatch to the appropriate subset. When adding a new category, make sure to also add it to the attribute
  """
  @categories [:permissions, :general]
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(_) do
    for category <- @categories do
      apply(__MODULE__, category, [])
    end
  end
end
