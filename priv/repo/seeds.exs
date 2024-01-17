# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
alias Radiator.{Accounts, Outline, Podcast}

{:ok, _user_bob} =
  Accounts.register_user(%{email: "bob@radiator.de", password: "supersupersecret"})

{:ok, _user_jim} =
  Accounts.register_user(%{email: "jim@radiator.de", password: "supersupersecret"})

{:ok, network} =
  Podcast.create_network(%{title: "Podcast network"})

{:ok, _show} =
  Podcast.create_show(%{title: "Dev Cafe", network_id: network.id})

{:ok, show} =
  Podcast.create_show(%{title: "Tech Weekly", network_id: network.id})

{:ok, _episode} =
  Podcast.create_episode(%{title: "past episode", show_id: show.id})

{:ok, current_episode} =
  Podcast.create_episode(%{title: "current episode", show_id: show.id})

{:ok, node1} =
  Outline.create_node(%{content: "Node 1", episode_id: current_episode.id})

{:ok, node2} =
  Outline.create_node(%{content: "Node 2", episode_id: current_episode.id, prev_id: node1.uuid})

{:ok, node3} =
  Outline.create_node(%{content: "Node 3", episode_id: current_episode.id, prev_id: node2.uuid})

{:ok, _node4} =
  Outline.create_node(%{content: "Node 4", episode_id: current_episode.id, prev_id: node3.uuid})

{:ok, node21} =
  Outline.create_node(%{
    content: "Node 2.1",
    episode_id: current_episode.id,
    parent_id: node2.uuid
  })

{:ok, _node22} =
  Outline.create_node(%{content: "Node 2.2", episode_id: current_episode.id, prev_id: node21.uuid})

{:ok, node211} =
  Outline.create_node(%{
    content: "Node 2.1.1",
    episode_id: current_episode.id,
    parent_id: node21.uuid
  })

{:ok, _node212} =
  Outline.create_node(%{
    content: "Node 2.1.2",
    episode_id: current_episode.id,
    prev_id: node211.uuid
  })
