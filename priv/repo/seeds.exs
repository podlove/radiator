# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Radiator.Repo.insert!(%Radiator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Radiator.{Accounts, Podcast}
alias Radiator.Outline.NodeRepository

{:ok, _user_bob} =
  Accounts.register_user(%{email: "bob@radiator.de", password: "supersupersecret"})

{:ok, _user_jim} =
  Accounts.register_user(%{email: "jim@radiator.de", password: "supersupersecret"})

{:ok, network} =
  Podcast.create_network(%{title: "Podcast network"})

{:ok, _show} =
  Podcast.create_show(%{
    title: "Dev Cafe",
    description: "Campfire chat between seasoned developers.",
    network_id: network.id
  })

{:ok, show} =
  Podcast.create_show(%{
    title: "Tech Weekly",
    description: "Weekly discussion on latest topic out of the tech sphere.",
    network_id: network.id
  })

{:ok, past_episode} =
  Podcast.create_episode(%{
    title: "past episode",
    show_id: show.id,
    number: 1,
    publish_date: Date.utc_today() |> Date.add(-23)
  })

{:ok, current_episode} =
  Podcast.create_episode(%{
    title: "current episode",
    show_id: show.id,
    number: 2,
    publish_date: Date.utc_today() |> Date.add(23)
  })

{:ok, node1} =
  NodeRepository.create_node(%{
    "content" => "Node 1",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id
  })

{:ok, node2} =
  NodeRepository.create_node(%{
    "content" => "Node 2",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id,
    "prev_id" => node1.uuid
  })

{:ok, node3} =
  NodeRepository.create_node(%{
    "content" => "Node 3",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id,
    "prev_id" => node2.uuid
  })

{:ok, _node4} =
  NodeRepository.create_node(%{
    "content" => "Node 4",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id,
    "prev_id" => node3.uuid
  })

{:ok, node21} =
  NodeRepository.create_node(%{
    "content" => "Node 2.1",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id,
    "parent_id" => node2.uuid
  })

{:ok, _node22} =
  NodeRepository.create_node(%{
    "content" => "Node 2.2",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id,
    "parent_id" => node2.uuid,
    "prev_id" => node21.uuid
  })

{:ok, node211} =
  NodeRepository.create_node(%{
    "content" => "Node 2.1.1",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id,
    "parent_id" => node21.uuid
  })

{:ok, _node212} =
  NodeRepository.create_node(%{
    "content" => "Node 2.1.2",
    "show_id" => current_episode.show_id,
    "episode_id" => current_episode.id,
    "parent_id" => node21.uuid,
    "prev_id" => node211.uuid
  })

{:ok, _past_parent_node} =
  NodeRepository.create_node(%{
    "content" => "Old Content",
    "show_id" => current_episode.show_id,
    "episode_id" => past_episode.id
  })
