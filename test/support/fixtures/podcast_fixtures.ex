defmodule Radiator.PodcastFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Radiator.Podcast` context.
  """
  alias Radiator.Podcast

  @doc """
  Generate a network.
  """
  def network_fixture(attrs \\ %{}) do
    {:ok, network} =
      attrs
      |> Enum.into(%{
        title: "metanetwork"
      })
      |> Podcast.create_network()

    network
  end

  @doc """
  Generate a show.
  """
  def show_fixture(attrs \\ %{}, hosts \\ []) do
    network = extract_network(attrs)

    {:ok, show} =
      attrs
      |> Enum.into(%{
        title: "some title",
        network_id: network.id
      })
      |> Podcast.create_show(hosts)

    show
  end

  @doc """
  Generate a episode.
  """
  def episode_fixture(attrs \\ %{}) do
    show = extract_show(attrs)
    number = Podcast.get_next_episode_number(show.id)

    {:ok, episode} =
      attrs
      |> Enum.into(%{
        title: "my show episode 23",
        show_id: show.id,
        number: number
      })
      |> Podcast.create_episode()

    episode
  end

  defp extract_network(%{network_id: id}), do: Podcast.get_network!(id)
  defp extract_network(_), do: network_fixture()

  defp extract_show(%{show_id: id}), do: Podcast.get_show!(id)
  defp extract_show(_), do: show_fixture()
end
