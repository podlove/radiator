defmodule Radiator.AuthFixtures do
  @moduledoc """
  Signing a user in for tests that go through the web layer.

  Shared by `RadiatorWeb.ConnCase` and `RadiatorWeb.FeatureCase`, which both
  need it and would otherwise each keep their own copy — copies that drift the
  moment the authentication setup gains a strategy or a required field.
  """

  alias AshAuthentication.BcryptProvider
  alias AshAuthentication.Info
  alias AshAuthentication.Plug.Helpers
  alias AshAuthentication.Strategy
  alias Radiator.Accounts.User

  @password "password"

  @doc """
  Seeds a user, signs them in and puts the result into the session.

  Going through a real sign-in rather than handing `store_in_session/2` a
  seeded struct is deliberate: the strategy is what produces the token the
  session subject refers to.
  """
  def register_and_log_in_user(%{conn: conn} = context) do
    user = register_user()

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Helpers.store_in_session(user)

    context |> Map.put(:conn, conn) |> Map.put(:user, user)
  end

  @doc "Seeds a user and returns them signed in, token and all."
  def register_user(email \\ "user@example.com") do
    {:ok, hashed_password} = BcryptProvider.hash(@password)

    Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})

    strategy = Info.strategy!(User, :password)

    {:ok, user} = Strategy.action(strategy, :sign_in, %{email: email, password: @password}, [])

    user
  end
end
