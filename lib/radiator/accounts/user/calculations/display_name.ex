defmodule Radiator.Accounts.User.Calculations.DisplayName do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [:person]

  @impl true
  def calculate(users, _opts, _context) do
    Enum.map(users, fn user ->
      cond do
        match?(%{display_name: d} when is_binary(d) and d != "", user.person) ->
          user.person.display_name

        is_binary(user.handle) and user.handle != "" ->
          user.handle

        true ->
          to_string(user.email)
      end
    end)
  end
end
