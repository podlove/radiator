defmodule Radiator.WebFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Web` context.
  """
  alias Radiator.OutlineFixtures
  alias Radiator.Web

  @doc """
  Generate a url.
  """
  def url_fixture(attrs \\ %{}) do
    node_id = get_node_id(attrs)

    {:ok, url} =
      attrs
      |> Enum.into(%{
        size_bytes: 42,
        start_bytes: 42,
        url: "some url",
        node_id: node_id
      })
      |> Web.create_url()

    url
  end

  defp get_node_id(%{node_id: id}), do: id
  defp get_node_id(_), do: OutlineFixtures.node_fixture().uuid
end
