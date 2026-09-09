defmodule Radiator.Podcasts.PubSubTest do
  use Radiator.DataCase, async: false

  alias Radiator.FeedFixtures
  alias Radiator.Feeds.Parser
  alias Radiator.Podcasts

  setup do
    user = generate(user())
    podcast = Podcasts.create_podcast!(%{title: "Test Show"}, actor: user)
    {:ok, feed} = Parser.parse(FeedFixtures.read!("minimal.xml"))

    RadiatorWeb.Endpoint.subscribe("podcast:updated:#{podcast.id}")

    %{podcast: podcast, feed: feed}
  end

  test "apply_feed announces itself", %{podcast: podcast, feed: feed} do
    Ash.update!(podcast, %{feed: feed}, action: :apply_feed)

    assert_receive %Phoenix.Socket.Broadcast{topic: topic}, 1_000
    assert topic == "podcast:updated:#{podcast.id}"
  end

  test "mark_sync_failed announces itself", %{podcast: podcast} do
    Ash.update!(podcast, %{error: :timeout}, action: :mark_sync_failed)

    assert_receive %Phoenix.Socket.Broadcast{}, 1_000
  end

  test "an unrelated podcast stays quiet", %{feed: feed} do
    other_user = generate(user())
    other = Podcasts.create_podcast!(%{title: "Other"}, actor: other_user)

    Ash.update!(other, %{feed: feed}, action: :apply_feed)

    refute_receive %Phoenix.Socket.Broadcast{}, 200
  end
end
