defmodule Radiator.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Accounts` context.
  """
  alias Radiator.Accounts
  alias Radiator.Accounts.Raindrop

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
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
end
