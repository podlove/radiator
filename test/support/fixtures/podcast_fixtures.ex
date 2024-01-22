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
  def show_fixture(attrs \\ %{}) do
    network = get_network(attrs)

    {:ok, show} =
      attrs
      |> Enum.into(%{
        title: "some title",
        network_id: network.id
      })
      |> Podcast.create_show()

    show
  end

  @doc """
  Generate a episode.
  """
  def episode_fixture(attrs \\ %{}) do
    show = get_show(attrs)

    {:ok, episode} =
      attrs
      |> Enum.into(%{
        title: "my show episode 23",
        show_id: show.id
      })
      |> Podcast.create_episode()

    episode
  end

  defp get_network(%{network_id: id}), do: Podcast.get_network!(id)
  defp get_network(_), do: network_fixture()

  defp get_show(%{show_id: id}), do: Podcast.get_show!(id)
  defp get_show(_), do: show_fixture()
end
