defmodule Radiator.WebFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Web` context.
  """

  alias Radiator.Web

  @doc """
  Generate a url.
  """
  def url_fixture(attrs \\ %{}) do
    {:ok, url} =
      attrs
      |> Enum.into(%{
        size_bytes: 42,
        start_bytes: 42,
        url: "some url"
      })
      |> Web.create_url()

    url
  end
end
