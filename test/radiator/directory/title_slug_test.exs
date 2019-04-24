defmodule Radiator.Directory.TitleSlugTest do
  use Radiator.DataCase, async: true

  alias Radiator.Directory.{Episode, Podcast, TitleSlug}

  import Radiator.Factory

  describe "get_sources/2" do
    test "extracts the title of a given Podcast changeset, when published_at is set" do
      podcast = insert(:podcast)
      podcast_title = podcast.title
      podcast_changeset = Podcast.changeset(podcast, %{published_at: DateTime.utc_now()})

      assert [^podcast_title] = TitleSlug.get_sources(podcast_changeset, [])
    end

    test "extracts the title of a given Episode changeset, when published_at is set" do
      episode = insert(:episode)
      episode_title = episode.title
      episode_changeset = Episode.changeset(episode, %{published_at: DateTime.utc_now()})

      assert [^episode_title] = TitleSlug.get_sources(episode_changeset, [])
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
