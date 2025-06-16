defmodule RadiatorWeb.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use RadiatorWeb, :verified_routes

      import RadiatorWeb.FeatureCase

      import PhoenixTest
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Radiator.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
