defmodule Radiator.Directory.TitleSlugTest do
  use Radiator.DataCase, async: true

  alias Radiator.Directory.{Episode, Network, Podcast, TitleSlug}

  import Radiator.Factory

  describe "get_sources/2" do
    test "extracts the title of a given Network changeset" do
      changeset = Network.changeset(%Network{}, %{title: "Network get_sources Test"})

      assert ["Network get_sources Test"] == TitleSlug.get_sources(changeset, [])
    end

    test "extracts the title of a given Podcast changeset, when published_at is set" do
      podcast = insert(:podcast)
      title = podcast.title
      changeset = Podcast.changeset(podcast, %{published_at: DateTime.utc_now()})

      assert [^title] = TitleSlug.get_sources(changeset, [])
    end

    test "extracts the title of a given Episode changeset, when published_at is set" do
      episode = insert(:episode)
      title = episode.title
      changeset = Episode.changeset(episode, %{published_at: DateTime.utc_now()})

      assert [^title] = TitleSlug.get_sources(changeset, [])
    end

    test "returns nil, for Podcast without published_at" do
      podcast = insert(:podcast)
      changeset = Podcast.changeset(podcast, %{})

      assert nil == TitleSlug.get_sources(changeset, [])
    end

    test "returns nil, for Episode without published_at" do
      episode = insert(:episode)
      changeset = Episode.changeset(episode, %{})

      assert nil == TitleSlug.get_sources(changeset, [])
    end
  end

  describe "build_slug/2" do
    test "generates a slug from the given sources and Network changeset" do
      changeset = Network.changeset(%Network{}, %{title: "Network build_slug Test"})
      sources = TitleSlug.get_sources(changeset, [])

      assert "network-build-slug-test" == TitleSlug.build_slug(sources, changeset)
    end

    test "generates a slug from the given sources and Podcast changeset" do
      podcast = insert(:podcast, title: "Podcast Slug Test")
      changeset = Podcast.changeset(podcast, %{published_at: DateTime.utc_now()})
      sources = TitleSlug.get_sources(changeset, [])

      assert "podcast-slug-test" == TitleSlug.build_slug(sources, changeset)
    end

    test "generates a slug from the given sources and Episode changeset" do
      episode = insert(:episode, title: "Episode Slug Test")
      changeset = Episode.changeset(episode, %{published_at: DateTime.utc_now()})
      sources = TitleSlug.get_sources(changeset, [])

      assert "episode-slug-test" == TitleSlug.build_slug(sources, changeset)
    end

    test "generates sequential slug, when there is already a Network using the original" do
      existing_network =
        insert(:network, %{
          title: "Sequential Network Slug Test",
          slug: "sequential-network-slug-test"
        })

      changeset = Network.changeset(%Network{}, %{title: existing_network.title})
      sources = TitleSlug.get_sources(changeset, [])

      assert "sequential-network-slug-test-1" == TitleSlug.build_slug(sources, changeset)
    end

    test "generates sequential slug, when there is already a Podcast using the original" do
      existing_podcast =
        insert(:podcast, %{
          title: "Sequential Podcast Slug Test",
          slug: "sequential-podcast-slug-test",
          published_at: DateTime.utc_now()
        })

      changeset =
        insert(:podcast, title: existing_podcast.title)
        |> Podcast.changeset(%{published_at: DateTime.utc_now()})

      sources = TitleSlug.get_sources(changeset, [])

      assert "sequential-podcast-slug-test-1" == TitleSlug.build_slug(sources, changeset)
    end

    test "generates sequential slug, when there is already an Episode using the original" do
      existing_episode =
        insert(:episode, %{
          title: "Sequential Episode Slug Test",
          slug: "sequential-episode-slug-test",
          published_at: DateTime.utc_now()
        })

      changeset =
        insert(:episode, title: existing_episode.title)
        |> Episode.changeset(%{published_at: DateTime.utc_now()})

      sources = TitleSlug.get_sources(changeset, [])

      assert "sequential-episode-slug-test-1" == TitleSlug.build_slug(sources, changeset)
    end
  end
end
