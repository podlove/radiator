defmodule Radiator.Podcasts.PodcastTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts

  setup do
    %{user: generate(user())}
  end

  test "lists episodes newest first by publication date, undated ones last", %{user: user} do
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

    for {guid, number, published_at} <- [
          {"a", 1, ~U[2026-08-01 10:00:00Z]},
          {"b", nil, ~U[2026-09-01 10:00:00Z]},
          {"c", 2, ~U[2026-08-15 10:00:00Z]},
          {"d", 3, nil}
        ] do
      Podcasts.create_episode!(%{
        podcast_id: podcast.id,
        guid: guid,
        title: guid,
        number: number,
        published_at: published_at
      })
    end

    loaded = Ash.load!(podcast, :episodes)

    assert Enum.map(loaded.episodes, & &1.guid) == ["b", "c", "a", "d"]
  end

  test "holds the HTTP cache values but does not accept them from outside", %{user: user} do
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

    assert {:error, %Ash.Error.Invalid{}} = Ash.update(podcast, %{http_etag: ~s("abc")})

    updated =
      podcast
      |> Ash.Changeset.for_update(:update, %{})
      |> Ash.Changeset.force_change_attribute(:http_etag, ~s("abc"))
      |> Ash.Changeset.force_change_attribute(
        :http_last_modified,
        "Fri, 28 Aug 2026 17:14:26 GMT"
      )
      |> Ash.update!()

    assert updated.http_etag == ~s("abc")
    assert updated.http_last_modified == "Fri, 28 Aug 2026 17:14:26 GMT"
  end

  test "does not let sync_status be set from outside", %{user: user} do
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)

    assert {:error, %Ash.Error.Invalid{}} = Ash.update(podcast, %{sync_status: :succeeded})
  end
end
