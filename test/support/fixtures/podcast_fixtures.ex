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
    network = network_fixture()

    {:ok, show} =
      attrs
      |> Enum.into(%{
        hostname: "some hostname",
        title: "some title",
        network: network
      })
      |> Podcast.create_show()

    show
  end

  @doc """
  Generate a episode.
  """
  def episode_fixture(attrs \\ %{}) do
    show = show_fixture()

    {:ok, episode} =
      attrs
      |> Enum.into(%{
        title: "my show episode 23",
        show_id: show.id
      })
      |> Podcast.create_episode()

    episode
  end
end
