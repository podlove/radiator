defmodule Radiator.BuilderTest do
  use ExUnit.Case

  alias Radiator.Directory.{Episode, Podcast}
  alias Radiator.Feed.{Builder, EpisodeBuilder, PodcastBuilder}

  import SweetXml

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
      data =
        data_fixture(%{
          podcast: %Podcast{title: "Hello World"},
          episodes: [
            %Episode{title: "Ep 001"},
            %Episode{title: "Ep 002"}
          ]
        })

      rss = build_xml(data)

      assert "Hello World" == xpath(rss, ~x"//rss/channel/title/text()"s)
      assert ["Ep 001", "Ep 002"] == xpath(rss, ~x"//rss/channel/item/title/text()"sl)
    end

    test "pages feeds" do
      # todo: how to handle an empty feed/page with no episodes?
      data =
        data_fixture(%{
          podcast: %Podcast{title: "Hello World"},
          episodes: [
            %Episode{title: "Ep 001"},
            %Episode{title: "Ep 002"},
            %Episode{title: "Ep 003"}
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
      rss =
        build_episode_xml(%{}, %Episode{
          title: "Ep 001",
          subtitle: "sub",
          description: "desc",
          enclosure_url: "https://media.example.com/001.mp3",
          enclosure_type: "audio/mpeg",
          enclosure_length: 123
        })

      assert "Ep 001" == xpath(rss, ~x"//item/title/text()"s)
      assert "sub" == xpath(rss, ~x"//item/itunes:subtitle/text()"s)
      assert "desc" == xpath(rss, ~x"//item/description/text()"s)

      assert %{
               url: "https://media.example.com/001.mp3",
               type: "audio/mpeg",
               length: 123
             } ==
               xpath(rss, ~x"//item/enclosure",
                 url: ~x"./@url"s,
                 type: ~x"./@type"s,
                 length: ~x"./@length"i
               )
    end
  end
end
