defmodule Radiator.Podcasts.PodcastPoliciesTest do
  use Radiator.DataCase, async: true

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Podcast

  setup do
    owner = generate(user())
    other = generate(user())

    podcast =
      Podcasts.create_podcast!(
        %{title: "Owned", feed_url: "https://example.com/feed"},
        actor: owner
      )

    %{owner: owner, other: other, podcast: podcast}
  end

  test "only the owner may read through the primary action", %{
    podcast: podcast,
    owner: owner,
    other: other
  } do
    assert Ash.get!(Podcast, podcast.id, actor: owner).id == podcast.id
    assert {:error, %Ash.Error.Invalid{}} = Ash.get(Podcast, podcast.id, actor: other)
    assert {:error, %Ash.Error.Invalid{}} = Ash.get(Podcast, podcast.id)
  end

  test "anyone may read the public fields, signed in or not", %{podcast: podcast, other: other} do
    for opts <- [[], [actor: other]] do
      assert [seen] = Podcasts.public_read_podcasts!(opts)
      assert seen.id == podcast.id
      assert seen.title == "Owned"
      assert %Ash.ForbiddenField{} = seen.feed_url
    end
  end

  test "the owner may update", %{podcast: podcast, owner: owner} do
    assert Podcasts.update_podcast!(podcast, %{title: "Renamed"}, actor: owner).title == "Renamed"
  end

  test "a different user may not update", %{podcast: podcast, other: other} do
    assert {:error, %Ash.Error.Forbidden{}} =
             Podcasts.update_podcast(podcast, %{title: "Hijacked"}, actor: other)
  end

  test "without an actor nobody may update", %{podcast: podcast} do
    assert {:error, %Ash.Error.Forbidden{}} = Podcasts.update_podcast(podcast, %{title: "Anon"})
  end

  test "a different user may not request a sync", %{podcast: podcast, other: other} do
    assert {:error, %Ash.Error.Forbidden{}} = Podcasts.request_sync(podcast, %{}, actor: other)
  end

  test "a different user may not destroy", %{podcast: podcast, owner: owner, other: other} do
    assert {:error, %Ash.Error.Forbidden{}} = Podcasts.destroy_podcast(podcast, actor: other)
    assert Ash.get!(Podcast, podcast.id, actor: owner).id == podcast.id
  end

  test "the owner may destroy", %{podcast: podcast, owner: owner} do
    assert :ok = Podcasts.destroy_podcast(podcast, actor: owner)
    assert {:error, %Ash.Error.Invalid{}} = Ash.get(Podcast, podcast.id, actor: owner)
  end

  test "the Oban worker sees every field", %{podcast: podcast} do
    # `FetchFeed` reads `feed_url` off the record the worker loaded; a
    # `%Ash.ForbiddenField{}` there would break every sync.
    seen = Ash.get!(Podcast, podcast.id, context: %{private: %{ash_oban?: true}})

    assert seen.feed_url == "https://example.com/feed"
    refute match?(%Ash.ForbiddenField{}, seen.http_etag)
  end

  test "the Oban worker bypasses the owner check", %{podcast: podcast} do
    # The worker marks its calls in the changeset context; nothing else does.
    synced =
      podcast
      |> Ash.Changeset.for_update(:mark_sync_failed, %{error: :timeout},
        context: %{private: %{ash_oban?: true}}
      )
      |> Ash.update!()

    assert synced.sync_status == :failed
  end
end
