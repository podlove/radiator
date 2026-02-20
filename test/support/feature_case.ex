defmodule RadiatorWeb.FeatureCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias AshAuthentication.Plug.Helpers
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      use RadiatorWeb, :verified_routes

      import RadiatorWeb.FeatureCase

      import PhoenixTest
    end
  end

  setup tags do
    pid = Sandbox.start_owner!(Radiator.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def register_and_log_in_user(%{conn: conn} = context) do
    email = "user@example.com"
    password = "password"
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash(password)

    Ash.Seed.seed!(Radiator.Accounts.User, %{
      email: email,
      hashed_password: hashed_password
    })

    # Replace `:password` with the appropriate strategy for your application.
    strategy = AshAuthentication.Info.strategy!(Radiator.Accounts.User, :password)

    {:ok, user} =
      AshAuthentication.Strategy.action(strategy, :sign_in, %{
        email: email,
        password: password
      })

    new_conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Helpers.store_in_session(user)

    %{context | conn: new_conn}
  end
end
