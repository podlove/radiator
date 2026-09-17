defmodule Radiator.Accounts.Scope do
  @moduledoc """
  Authentication scope.

  Wraps the current actor and tenant in a single struct that implements
  `Ash.Scope.ToOpts`, so it can be passed to any Ash action as `scope:`:

      Ash.read!(query, scope: socket.assigns.current_user_scope)

  Grow this struct as your application does — add organisation, permissions,
  locale, and so on — and expose them through the `ToOpts` callbacks below.
  """

  defstruct [:actor, :tenant]

  defimpl Ash.Scope.ToOpts, for: __MODULE__ do
    def get_actor(%{actor: actor}), do: {:ok, actor}
    def get_tenant(%{tenant: tenant}), do: {:ok, tenant}
    def get_context(_scope), do: :error
    def get_tracer(_scope), do: :error
    def get_authorize?(_scope), do: :error
  end
end
