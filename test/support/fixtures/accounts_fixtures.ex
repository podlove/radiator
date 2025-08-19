defmodule Radiator.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Accounts` context.
  """
  alias Radiator.Accounts
  alias Radiator.Accounts.Scope
  alias Radiator.Accounts.Raindrop
  alias Radiator.Accounts.WebService
  alias Radiator.Repo
  
   import Ecto.Query

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Radiator.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Radiator.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Radiator.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  def raindrop_service_fixture(user \\ user_fixture()) do
    {:ok, service} =
      Raindrop.update_raindrop_tokens(
        user.id,
        "ae261404-11r4-47c0-bce3-e18a423da828",
        "c8080368-fad2-4a3f-b2c9-71d3z85011vb",
        DateTime.utc_now() |> DateTime.shift(second: 1_209_599) |> DateTime.truncate(:second)
      )

    service
  end

  def web_service_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    user = Map.get(attrs, :user) || user_fixture()
    service_name = Map.get(attrs, :service_name, "raindrop")

    default_data = %{
      access_token: "ae261404-11r4-47c0-bce3-e18a423da828",
      refresh_token: "c8080368-fad2-4a3f-b2c9-71d3z85011vb",
      expires_at:
        DateTime.utc_now() |> DateTime.shift(second: 1_209_599) |> DateTime.truncate(:second),
      mappings: []
    }

    data = Map.get(attrs, :data, default_data)
    last_sync = Map.get(attrs, :last_sync)

    service_attrs = %{
      service_name: service_name,
      user_id: user.id,
      data: data
    }

    service_attrs =
      if last_sync do
        Map.put(service_attrs, :last_sync, last_sync)
      else
        service_attrs
      end

    {:ok, service} =
      %WebService{}
      |> WebService.changeset(service_attrs)
      |> Repo.insert()

    service
  end
end
