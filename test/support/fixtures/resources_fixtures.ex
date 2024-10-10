defmodule Radiator.ResourcesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Resources` context.
  """
  alias Radiator.OutlineFixtures
  alias Radiator.Resources

  @doc """
  Generate a url.
  """
  def url_fixture(attrs \\ %{}) do
    node_id = get_node_id(attrs)

    {:ok, url} =
      attrs
      |> Enum.into(%{
        size_bytes: 42,
        start_bytes: 23,
        url: "https://elixirschool.com",
        node_id: node_id
      })
      |> Resources.create_url()

    url
  end

  defp get_node_id(%{node_id: id}), do: id
  defp get_node_id(_), do: OutlineFixtures.node_fixture().uuid
end
