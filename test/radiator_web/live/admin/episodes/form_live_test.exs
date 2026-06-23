defmodule RadiatorWeb.Admin.Episodes.FormLiveTest do
  use RadiatorWeb.FeatureCase, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Radiator.Generator

  require Ash.Query

  alias AshAuthentication.Plug.Helpers
  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode.Scheduling

  @endpoint RadiatorWeb.Endpoint

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp create_user(prefix) do
    email = "#{prefix}_#{System.unique_integer([:positive])}@example.com"
    password = "supersupersecret"
    {:ok, hashed_password} = AshAuthentication.BcryptProvider.hash(password)
    _user = Ash.Seed.seed!(User, %{email: email, hashed_password: hashed_password})

    strategy = AshAuthentication.Info.strategy!(User, :password)

    {:ok, user} =
      AshAuthentication.Strategy.action(strategy, :sign_in, %{email: email, password: password})

    user
  end

  defp log_in(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  defp authenticated_conn(conn, prefix) do
    user = create_user(prefix)
    {log_in(conn, user), user}
  end

  # ---------------------------------------------------------------------------
  # Unauthenticated
  # ---------------------------------------------------------------------------

  describe "without authentication" do
    test "redirects to /sign-in on new form", %{conn: conn} do
      podcast = generate(podcast())

      {:error, {:redirect, %{to: path}}} =
        live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

      assert path =~ "/sign-in"
    end
  end

  # ---------------------------------------------------------------------------
  # Create: signed-in user can add proposals
  # ---------------------------------------------------------------------------

  describe "new episode form as signed-in user" do
    setup %{conn: conn} do
      {conn, _user} = authenticated_conn(conn, "nouser")
      podcast = generate(podcast())
      {:ok, conn: conn, podcast: podcast}
    end

    test "renders the Add Proposal button", %{conn: conn, podcast: podcast} do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")
      assert has_element?(lv, "button", "Add Proposal")
    end

    test "clicking Add Proposal adds a proposal input for a signed-in user", %{
      conn: conn,
      podcast: podcast
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")
      lv |> element("button", "Add Proposal") |> render_click()
      assert has_element?(lv, "input[type='datetime-local']")
    end
  end

  # ---------------------------------------------------------------------------
  # Create: user as owner
  # ---------------------------------------------------------------------------

  describe "new episode form as owner user" do
    setup %{conn: conn} do
      {conn, user} = authenticated_conn(conn, "owner")
      podcast = generate(podcast())
      {:ok, conn: conn, user: user, podcast: podcast}
    end

    test "renders the form with title, proposals, and participants sections", %{
      conn: conn,
      podcast: podcast
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

      assert has_element?(lv, "input[name='form[title]']")
      assert has_element?(lv, "button", "Add Proposal")
      assert has_element?(lv, "button", "Add Participant")
    end

    test "clicking Add Proposal adds a date/time input", %{conn: conn, podcast: podcast} do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

      refute has_element?(lv, "input[type='datetime-local']")

      lv |> element("button", "Add Proposal") |> render_click()

      assert has_element?(lv, "input[type='datetime-local']")
    end

    test "clicking Add Proposal twice adds two date/time inputs", %{conn: conn, podcast: podcast} do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

      lv |> element("button", "Add Proposal") |> render_click()
      lv |> element("button", "Add Proposal") |> render_click()

      assert lv |> render() |> String.split("datetime-local") |> length() == 3
    end

    test "saving with a proposal creates episode, scheduling, and proposal", %{
      conn: conn,
      podcast: podcast,
      user: owner
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

      lv |> element("button", "Add Proposal") |> render_click()

      assert {:error, {:live_redirect, %{to: path}}} =
               lv
               |> form("#episode_form", %{
                 "form" => %{
                   "title" => "Test Episode With Proposal",
                   "scheduling" => %{
                     "owner_user_id" => owner.id,
                     "proposals" => %{
                       "0" => %{
                         "datetime" => "2026-09-01T14:00",
                         "created_by_user_id" => owner.id
                       }
                     }
                   }
                 }
               })
               |> render_submit()

      assert path =~ "/episodes/"

      episode =
        Radiator.Podcasts.Episode
        |> Ash.Query.filter(title == "Test Episode With Proposal")
        |> Ash.read_one!(authorize?: false)

      assert episode

      loaded = Ash.load!(episode, [:scheduling], authorize?: false)
      assert loaded.scheduling
      assert loaded.scheduling.owner_user_id == owner.id
      assert length(loaded.scheduling.proposals) == 1
    end

    test "saving without a proposal creates episode with no scheduling", %{
      conn: conn,
      podcast: podcast
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

      lv
      |> form("#episode_form", %{"form" => %{"title" => "Episode No Proposals"}})
      |> render_submit()

      episode =
        Radiator.Podcasts.Episode
        |> Ash.Query.filter(title == "Episode No Proposals")
        |> Ash.read_one!(authorize?: false)

      assert episode
      loaded = Ash.load!(episode, [:scheduling], authorize?: false)
      assert is_nil(loaded.scheduling)
    end

    test "remove proposal button removes the input row", %{conn: conn, podcast: podcast} do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/new")

      lv |> element("button", "Add Proposal") |> render_click()
      assert has_element?(lv, "input[type='datetime-local']")

      lv |> element("button[phx-click='remove_proposal']") |> render_click()
      refute has_element?(lv, "input[type='datetime-local']")
    end
  end

  # ---------------------------------------------------------------------------
  # Edit form
  # ---------------------------------------------------------------------------

  describe "edit episode form" do
    setup %{conn: conn} do
      {conn, user} = authenticated_conn(conn, "editor")
      podcast = generate(podcast())
      episode = generate(episode(%{podcast_id: podcast.id}))

      {:ok, scheduling} =
        Scheduling
        |> Ash.Changeset.for_create(:create, %{
          episode_id: episode.id,
          owner_user_id: user.id,
          proposed_datetimes: [~U[2026-10-01 14:00:00Z], ~U[2026-10-02 10:00:00Z]]
        })
        |> Ash.create(authorize?: false)

      {:ok, conn: conn, user: user, podcast: podcast, episode: episode, scheduling: scheduling}
    end

    test "loads existing proposals in the form", %{conn: conn, podcast: podcast, episode: episode} do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      # Two existing proposals should be present as datetime-local inputs
      html = render(lv)
      count = html |> String.split("datetime-local") |> length()
      assert count == 3
    end

    test "can add a proposal to an existing scheduling", %{
      conn: conn,
      podcast: podcast,
      episode: episode
    } do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      lv |> element("button", "Add Proposal") |> render_click()

      html = render(lv)
      count = html |> String.split("datetime-local") |> length()
      assert count == 4
    end

    test "can remove an existing proposal", %{conn: conn, podcast: podcast, episode: episode} do
      {:ok, lv, _html} = live(conn, ~p"/admin/podcasts/#{podcast.id}/episodes/#{episode.id}/edit")

      lv |> element("button[phx-value-path='form[scheduling][proposals][0]']") |> render_click()

      html = render(lv)
      count = html |> String.split("datetime-local") |> length()
      assert count == 2
    end
  end
end
