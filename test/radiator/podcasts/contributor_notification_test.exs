defmodule Radiator.Podcasts.ContributorNotificationTest do
  use Radiator.DataCase, async: true

  import Swoosh.TestAssertions

  require Ash.Query

  alias Radiator.Accounts.User
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Person

  setup do
    owner = generate(user(email: "alice@example.com"))
    podcast = Podcasts.create_podcast!(%{title: "Freak Show"}, actor: owner)
    episode = Podcasts.create_episode!(%{podcast_id: podcast.id, title: "Folge 1"})

    %{owner: owner, podcast: podcast, episode: episode}
  end

  defp flush_emails do
    receive do
      {:email, _} -> flush_emails()
    after
      0 -> :ok
    end
  end

  defp kept(episode) do
    episode
    |> Ash.load!(:contributors)
    |> Map.fetch!(:contributors)
    |> Enum.map(&%{"id" => &1.id})
  end

  defp save(episode, owner, new_rows, attrs \\ %{}) do
    Podcasts.update_episode(
      episode,
      Map.put(attrs, :contributors, kept(episode) ++ new_rows),
      actor: owner
    )
  end

  defp link_in(email) do
    [link] = Regex.run(~r{href="([^"]+)"}, email.html_body, capture: :all_but_first)
    URI.parse(link)
  end

  test "a new account gets the activation mail with a link to the scheduling page", %{
    owner: owner,
    podcast: podcast,
    episode: episode
  } do
    {:ok, _} = save(episode, owner, [%{"email" => "bob@example.com"}])

    assert_email_sent(fn email ->
      assert email.to == [{"", "bob@example.com"}]
      assert email.subject == "An account was created for you on Radiator"
      assert email.html_body =~ "alice@example.com added you"
      assert email.html_body =~ "Folge 1"

      uri = link_in(email)
      assert "/magic_link/" <> _token = uri.path

      assert URI.decode_query(uri.query) == %{
               "return_to" => "/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/scheduling"
             }
    end)
  end

  test "an existing account gets the added mail", %{owner: owner, episode: episode} do
    generate(user(email: "bob@example.com"))

    {:ok, _} = save(episode, owner, [%{"email" => "Bob@example.com"}])

    assert_email_sent(subject: "You were added to Folge 1", to: [{"", "bob@example.com"}])
  end

  test "picking a person with an account mails them too", %{owner: owner, episode: episode} do
    bob = generate(user(email: "bob@example.com"))

    person =
      Ash.create!(Person, %{name: "Bob", user_id: owner.id, account_id: bob.id}, action: :create)

    {:ok, _} = save(episode, owner, [%{"person_id" => person.id}])

    assert_email_sent(subject: "You were added to Folge 1", to: [{"", "bob@example.com"}])
  end

  test "persons without account and contributors already there get no mail", %{
    owner: owner,
    episode: episode
  } do
    {:ok, episode} = save(episode, owner, [%{"email" => "bob@example.com"}])
    flush_emails()
    feed_person = Ash.create!(Person, %{name: "From Feed", user_id: owner.id}, action: :create)

    {:ok, _} = save(episode, owner, [%{"person_id" => feed_person.id}], %{title: "Renamed"})

    assert_no_email_sent()
  end

  test "whoever saves gets no mail about adding themselves", %{owner: owner, episode: episode} do
    {:ok, _} = save(episode, owner, [%{"email" => "alice@example.com"}])

    assert_no_email_sent()
  end

  test "the same address in two rows gets one mail", %{owner: owner, episode: episode} do
    {:ok, _} =
      save(episode, owner, [%{"email" => "bob@example.com"}, %{"email" => "BOB@example.com"}])

    assert_email_sent(to: [{"", "bob@example.com"}])
    assert_no_email_sent()
  end

  # The second row fails after the first one created its user: the rollback
  # must take that user with it.
  test "a failed save creates no user and sends nothing", %{owner: owner, episode: episode} do
    assert {:error, _} =
             save(episode, owner, [%{"email" => "bob@example.com"}, %{"email" => "nope"}])

    assert_no_email_sent()

    assert [] =
             User
             |> Ash.Query.filter(email == "bob@example.com")
             |> Ash.read!(authorize?: false)
  end

  test "a new episode mails its contributors", %{owner: owner, podcast: podcast} do
    {:ok, episode} =
      Podcasts.create_episode(
        %{podcast_id: podcast.id, title: "Neu", contributors: [%{"email" => "bob@example.com"}]},
        actor: owner
      )

    assert_email_sent(fn email ->
      assert URI.decode_query(link_in(email).query)["return_to"] ==
               "/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/scheduling"
    end)
  end
end
