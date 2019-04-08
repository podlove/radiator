defmodule Radiator.Auth.Config do
  @moduledoc """
  Radiator Authentication Configuration MOdule.

  Provides a small wrapper around `Application.get_env(:radiator, :auth)`, providing an accessor function for each configuration item.


  """

  [
    :email_from_email,
    :email_from_name,
    :log_emails
  ]
  |> Enum.each(fn
    {key, default} ->
      def unquote(key)(opts \\ unquote(default)) do
        get_application_env(unquote(key), opts)
      end

    key ->
      def unquote(key)(opts \\ nil) do
        get_application_env(unquote(key), opts)
      end
  end)

  defp get_application_env(key, default) do
    case Application.get_env(:radiator, :auth, default)[key] do
      {:system, env_var} -> System.get_env(env_var)
      value -> value
    end
  end
end
