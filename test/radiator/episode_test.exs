defmodule Radiator.EpisodeTest do
  use Radiator.DataCase, async: true

  import Ash.Test
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode

  describe "Episode" do
    setup do
      %{episode: generate(episode()), user: generate(user())}
    end

    test "adds a participant", %{episode: episode, user: user} do
      {:ok, %{participants: [added_participant]}} =
        Podcasts.add_participant_to_episode(episode, user)

      assert_stripped added_participant == user
    end

    test "removes a participant", %{episode: episode, user: user} do
      {:ok, %{participants: [_added_participant]}} =
        Podcasts.add_participant_to_episode(episode, user)

      {:ok, %{participants: []}} = Podcasts.remove_participant_from_episode(episode, user)
    end
  end

  describe "Episode :create with scheduling" do
    test "creates episode with scheduling and proposals in one call" do
      podcast = generate(podcast())
      owner = generate(user())

      proposals = [
        %{datetime: ~U[2026-08-01 14:00:00Z], created_by_user_id: owner.id},
        %{datetime: ~U[2026-08-02 10:00:00Z], created_by_user_id: owner.id}
      ]

      assert {:ok, episode} =
               Episode
               |> Ash.Changeset.for_create(
                 :create,
                 %{
                   title: "My Episode",
                   podcast_id: podcast.id,
                   scheduling: %{owner_user_id: owner.id, proposals: proposals}
                 },
                 authorize?: false
               )
               |> Ash.create(authorize?: false)

      loaded = Ash.load!(episode, [:scheduling], authorize?: false)

      assert loaded.scheduling.episode_id == episode.id
      assert loaded.scheduling.owner_user_id == owner.id
      assert loaded.scheduling.status == :open
      assert length(loaded.scheduling.proposals) == 2
    end

    test "creates episode without scheduling when scheduling param is omitted" do
      podcast = generate(podcast())

      assert {:ok, episode} =
               Episode
               |> Ash.Changeset.for_create(
                 :create,
                 %{title: "No Scheduling Episode", podcast_id: podcast.id},
                 authorize?: false
               )
               |> Ash.create(authorize?: false)

      loaded = Ash.load!(episode, [:scheduling], authorize?: false)
      assert is_nil(loaded.scheduling)
    end

    test "creates scheduling with no proposals" do
      podcast = generate(podcast())
      owner = generate(user())

      assert {:ok, episode} =
               Episode
               |> Ash.Changeset.for_create(
                 :create,
                 %{
                   title: "Episode No Proposals",
                   podcast_id: podcast.id,
                   scheduling: %{owner_user_id: owner.id, proposals: []}
                 },
                 authorize?: false
               )
               |> Ash.create(authorize?: false)

      loaded = Ash.load!(episode, [:scheduling], authorize?: false)
      assert loaded.scheduling.proposals == []
    end
  end

  describe "Episode :update adding scheduling to an existing episode" do
    test "creates scheduling via update when none existed before" do
      podcast = generate(podcast())
      owner = generate(user())
      episode = generate(episode(%{podcast_id: podcast.id}))

      assert {:ok, updated} =
               episode
               |> Ash.Changeset.for_update(
                 :update,
                 %{scheduling: %{owner_user_id: owner.id, proposals: []}},
                 authorize?: false
               )
               |> Ash.update(authorize?: false)

      loaded = Ash.load!(updated, [:scheduling], authorize?: false)
      assert loaded.scheduling.episode_id == episode.id
      assert loaded.scheduling.owner_user_id == owner.id
    end
  end
end
