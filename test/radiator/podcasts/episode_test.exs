defmodule Radiator.Podcasts.EpisodeTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode.Chapter

  setup do
    user = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

    %{user: user, podcast: podcast}
  end

  test "creates an episode with every feed field", %{podcast: podcast} do
    episode =
      Podcasts.create_episode!(%{
        podcast_id: podcast.id,
        guid: "item-1",
        title: "Vollständige Episode",
        number: 1,
        season: 1,
        episode_type: :full,
        subtitle: "Untertitel eins",
        summary: "Zusammenfassung eins",
        content_html: "<p>Volltext</p>",
        link: "https://example.com/e1",
        published_at: ~U[2026-08-28 17:14:26Z],
        duration_seconds: 3723,
        image_url: "https://example.com/e1.jpg",
        enclosure_url: "https://example.com/e1.mp3",
        enclosure_length: 149_856_131,
        enclosure_type: "audio/mpeg",
        chapters: [%{start_ms: 0, title: "Intro"}],
        transcripts: [%{url: "https://example.com/e1.vtt", type: "text/vtt"}]
      })

    assert episode.episode_type == :full
    assert episode.duration_seconds == 3723
    assert [%Chapter{start_ms: 0, title: "Intro"}] = episode.chapters
    assert [%{url: "https://example.com/e1.vtt"}] = episode.transcripts
  end

  test "refuses last_seen_in_feed_at as input, the way the http cache is refused", %{
    podcast: podcast
  } do
    assert {:error, %Ash.Error.Invalid{}} =
             Podcasts.create_episode(%{
               podcast_id: podcast.id,
               title: "Von Hand",
               last_seen_in_feed_at: ~U[2099-01-01 00:00:00.000000Z]
             })
  end

  test "rejects the same guid twice within one podcast", %{podcast: podcast} do
    Podcasts.create_episode!(%{podcast_id: podcast.id, guid: "item-1", title: "Erste"})

    assert {:error, %Ash.Error.Invalid{}} =
             Podcasts.create_episode(%{podcast_id: podcast.id, guid: "item-1", title: "Nochmal"})
  end

  test "allows the same guid across different podcasts", %{podcast: podcast, user: user} do
    other = Podcasts.create_podcast!(%{title: "Andere Show"}, actor: user)

    Podcasts.create_episode!(%{podcast_id: podcast.id, guid: "item-1", title: "Erste"})

    assert %{guid: "item-1"} =
             Podcasts.create_episode!(%{podcast_id: other.id, guid: "item-1", title: "Erste"})
  end

  test "allows hand-created episodes without a guid", %{podcast: podcast} do
    assert %{guid: nil, last_seen_in_feed_at: nil} =
             Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Von Hand"})

    assert %{guid: nil} =
             Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Auch von Hand"})
  end
end
