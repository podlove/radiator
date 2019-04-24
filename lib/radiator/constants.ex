defmodule Radiator.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @otp_app Mix.Project.config()[:app]

      @permission_values [:readonly, :edit, :manage, :own]
      @auth_user_status_values [:unverified, :active, :suspended]

      defguard is_permission(p) when p in @permission_values
      defguard is_user_status(s) when s in @auth_user_status_values
    end
  end
end
