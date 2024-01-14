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

{:ok, _node} =
  Outline.create_node(%{content: "This is my first node", episode_id: current_episode.id})

{:ok, _node} =
  Outline.create_node(%{content: "Second node", episode_id: current_episode.id})
