defmodule Radiator.BuilderTest do
  use Radiator.DataCase

  alias Radiator.Directory.Podcast
  alias Radiator.Feed.{Builder, EpisodeBuilder, PodcastBuilder}

  import SweetXml
  import Radiator.Factory

  defp data_fixture(data) do
    default = %{
      podcast: %Podcast{},
      episodes: [],
      urls: %{
        main: "",
        self: "",
        page_template: ""
      }
    }

    Map.merge(default, data)
    |> Map.put(:urls, Map.merge(default.urls, Map.get(data, :urls, %{})))
  end

  defp build_xml(data, opts \\ [items_per_page: 50]) do
    data
    |> Builder.new(opts)
    |> Builder.render()
  end

  defp build_podcast_xml(data, opts \\ [items_per_page: 50]) do
    data
    |> PodcastBuilder.new(opts)
    |> Builder.render()
  end

  defp build_episode_xml(data, episode) do
    data
    |> EpisodeBuilder.new(episode)
    |> Builder.render()
  end

  describe "Radiator.Feed.Builder" do
    test "builds an RSS feed" do
      podcast = insert(:podcast, title: "Hello World")
      episode1 = insert(:episode, podcast: podcast, title: "Ep 001")
      episode2 = insert(:episode, podcast: podcast, title: "Ep 002")

      data =
        data_fixture(%{
          podcast: podcast,
          episodes: [
            episode1,
            episode2
          ]
        })

      rss = build_xml(data)

      assert "Hello World" == xpath(rss, ~x"//rss/channel/title/text()"s)
      assert ["Ep 001", "Ep 002"] == xpath(rss, ~x"//rss/channel/item/title/text()"sl)
    end

    test "pages feeds" do
      podcast = insert(:podcast, title: "Hello World")
      episode1 = insert(:episode, podcast: podcast)
      episode2 = insert(:episode, podcast: podcast)
      episode3 = insert(:episode, podcast: podcast)

      # todo: how to handle an empty feed/page with no episodes?
      data =
        data_fixture(%{
          podcast: podcast,
          episodes: [
            episode1,
            episode2,
            episode3
          ]
        })

      assert ["Ep 001", "Ep 002"] ==
               xpath(
                 build_xml(data, items_per_page: 2, page: 1),
                 ~x"//rss/channel/item/title/text()"sl
               )

      assert ["Ep 003"] ==
               xpath(
                 build_xml(data, items_per_page: 2, page: 2),
                 ~x"//rss/channel/item/title/text()"sl
               )

      assert_raise ArgumentError, ~r/^invalid items per page \d+/, fn ->
        build_xml(data, items_per_page: 0)
      end

      assert_raise ArgumentError, ~r/^invalid feed page \d+/, fn ->
        build_xml(data, page: 0)
      end
    end
  end

  describe "Radiator.Feed.PodcastBuilder" do
    test "has atom:link self reference" do
      data =
        data_fixture(%{
          podcast: %Podcast{id: 1, title: "Hello World"},
          urls: %{
            self: "/dummy/self/url",
            main: "/dummy/self/url"
          }
        })

      xml = build_podcast_xml(data)

      assert %{
               type: "application/rss+xml",
               href: "/dummy/self/url",
               rel: "self"
             } ==
               xmap(
                 xml,
                 type: ~x"//atom:link[@rel = \"self\"]/@type"s,
                 href: ~x"//atom:link[@rel = \"self\"]/@href"s,
                 rel: ~x"//atom:link[@rel = \"self\"]/@rel"s
               )
    end
  end

  describe "Radiator.Feed.EpisodeBuilder" do
    test "builds an item" do
      episode = insert(:episode, title: "Ep 001", subitle: "sub", description: "desc")

      rss = build_episode_xml(%{}, episode)

      assert "Ep 001" == xpath(rss, ~x"//item/title/text()"s)
      assert "sub" == xpath(rss, ~x"//item/itunes:subtitle/text()"s)
      assert "desc" == xpath(rss, ~x"//item/description/text()"s)

      [enclosure] = episode.audio.audio_files

      assert %{
               url: Radiator.Media.AudioFile.url({enclosure.file, enclosure}),
               type: enclosure.mime_type,
               length: enclosure.byte_length
             } ==
               xpath(rss, ~x"//item/enclosure",
                 url: ~x"./@url"s,
                 type: ~x"./@type"s,
                 length: ~x"./@length"i
               )
    end
  end
end
