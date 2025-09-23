defmodule Radiator.Seeds do
  alias Radiator.{Accounts, Podcast}
  alias Radiator.Outline.NodeRepository

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: "supersupersecret"})

    user
  end

  def run_seeds() do
    {:ok, user_bob} =
      Accounts.register_user(%{email: "bob@radiator.de"})

    set_password(user_bob)

    {:ok, user_jim} =
      Accounts.register_user(%{email: "jim@radiator.de"})

    set_password(user_jim)

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

    {:ok, _past_episode} =
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

    container_id = current_episode.outline_node_container_id
    inbox_id = show.inbox_node_container_id

    {:ok, node1} =
      NodeRepository.create_node(%{
        "content" => "Node 1",
        "container_id" => container_id
      })

    {:ok, node2} =
      NodeRepository.create_node(%{
        "content" => "Node 2",
        "container_id" => container_id,
        "prev_id" => node1.uuid
      })

    {:ok, node3} =
      NodeRepository.create_node(%{
        "content" => "Node 3",
        "container_id" => container_id,
        "prev_id" => node2.uuid
      })

    {:ok, _node4} =
      NodeRepository.create_node(%{
        "content" => "Node 4",
        "container_id" => container_id,
        "prev_id" => node3.uuid
      })

    {:ok, node21} =
      NodeRepository.create_node(%{
        "content" => "Node 2.1",
        "container_id" => container_id,
        "parent_id" => node2.uuid
      })

    {:ok, _node22} =
      NodeRepository.create_node(%{
        "content" => "Node 2.2",
        "container_id" => container_id,
        "parent_id" => node2.uuid,
        "prev_id" => node21.uuid
      })

    {:ok, node211} =
      NodeRepository.create_node(%{
        "content" => "Node 2.1.1",
        "container_id" => container_id,
        "parent_id" => node21.uuid
      })

    {:ok, _node212} =
      NodeRepository.create_node(%{
        "content" => "Node 2.1.2",
        "container_id" => container_id,
        "parent_id" => node21.uuid,
        "prev_id" => node211.uuid
      })

    {:ok, inbox1} =
      NodeRepository.create_node(%{
        "content" => "Raindrop",
        "container_id" => inbox_id,
        "parent_id" => nil,
        "prev_id" => nil
      })

    {:ok, inbox11} =
      NodeRepository.create_node(%{
        "content" => "https://metaebene.me",
        "container_id" => inbox_id,
        "parent_id" => inbox1.uuid,
        "prev_id" => nil
      })

    {:ok, inbox12} =
      NodeRepository.create_node(%{
        "content" => "https://freakshow.fm",
        "container_id" => inbox_id,
        "parent_id" => inbox1.uuid,
        "prev_id" => inbox11.uuid
      })

    {:ok, _inbox13} =
      NodeRepository.create_node(%{
        "content" => "https://logbuch-netzpolitik.de",
        "container_id" => inbox_id,
        "parent_id" => inbox1.uuid,
        "prev_id" => inbox12.uuid
      })
  end
end

Radiator.Seeds.run_seeds()
