defmodule RadiatorWeb.PodcastInvitationTest do
  use RadiatorWeb.ConnCase, async: true

  import Swoosh.TestAssertions

  alias Radiator.Podcasts

  setup do
    alice = generate(user(email: "alice@example.com"))
    podcast = Podcasts.create_podcast!(%{title: "Freak Show"}, actor: alice)

    %{alice: alice, podcast: podcast}
  end

  defp invite(podcast, alice, email) do
    Podcasts.update_podcast!(
      podcast,
      %{
        memberships: [
          %{"id" => hd(Ash.load!(podcast, :memberships, authorize?: false).memberships).id},
          %{"email" => email}
        ]
      },
      actor: alice
    )

    assert_email_sent(fn email ->
      assert email.subject == "You have been added to Freak Show"
      assert email.html_body =~ "alice@example.com added you"

      send(
        self(),
        {:link, Regex.run(~r{href="([^"]+)"}, email.html_body, capture: :all_but_first)}
      )
    end)

    assert_received {:link, [link]}
    URI.parse(link)
  end

  test "the invitation links to the edit page through the magic link", %{
    alice: alice,
    podcast: podcast
  } do
    uri = invite(podcast, alice, "bob@example.com")

    assert "/magic_link/" <> _token = uri.path
    assert URI.decode_query(uri.query) == %{"return_to" => "/admin/podcasts/#{podcast.id}/edit"}
  end

  test "following the link signs in and lands on the podcast's edit page", %{
    conn: conn,
    alice: alice,
    podcast: podcast
  } do
    uri = invite(podcast, alice, "bob@example.com")
    "/magic_link/" <> token = uri.path

    conn = get(conn, uri.path <> "?" <> uri.query)
    assert get_session(conn, :return_to) == "/admin/podcasts/#{podcast.id}/edit"

    conn = conn |> recycle() |> post(~p"/auth/user/magic_link", %{"user" => %{"token" => token}})

    assert redirected_to(conn) == "/admin/podcasts/#{podcast.id}/edit"
  end

  for foreign <- ["https://evil.example", "//evil.example", "/\\\\evil.example", "show"] do
    test "a return_to of #{inspect(foreign)} is ignored", %{conn: conn} do
      conn =
        get(conn, "/magic_link/whatever?" <> URI.encode_query(%{return_to: unquote(foreign)}))

      assert is_nil(get_session(conn, :return_to))
    end
  end
end
