defmodule Features.OutlineHooksTest do
  use PhoenixTest.Playwright.Case, async: false
  use RadiatorWeb, :verified_routes

  import Radiator.AccountsFixtures
  import Radiator.PodcastFixtures
  import Radiator.OutlineFixtures

  test "outline hooks", %{conn: conn} do
    email = "user@example.com"
    password = "Mb2.r5oHf-0t"

    _user = user_fixture(%{email: email, password: password})
    show = show_fixture()

    %{outline_node_container_id: outline_node_container_id} =
      episode_fixture(%{show_id: show.id})

    _node_1 =
      node_fixture(
        container_id: outline_node_container_id,
        parent_id: nil,
        prev_id: nil,
        content: "node_1"
      )

    conn
    |> visit(~p"/")
    |> click_link("Log in")
    |> assert_has("body .phx-connected")
    |> fill_in("Email", with: email)
    |> fill_in("Password", with: password)
    |> click_button("Log in")
    |> assert_has("#flash-info", text: "Success!")
    |> visit(~p"/admin/podcast/#{show}")
    |> assert_has("h1", text: show.title)
    |> assert_has(".node", text: "node_1")
  end
end
