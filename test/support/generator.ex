defmodule Radiator.Generator do
  @moduledoc """
  This module provides functions to generate and seed test data.
  """

  use Ash.Generator

  alias Radiator.Accounts.User

  def user(opts \\ []) do
    seed_generator(
      %User{email: sequence(:user_email, &"user#{&1}@example.com")},
      overrides: opts
    )
  end
end
