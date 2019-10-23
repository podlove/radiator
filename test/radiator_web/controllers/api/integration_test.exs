defmodule RadiatorWeb.Api.IntegrationTest do
  use RadiatorWeb.ConnCase

  import Radiator.Factory

  def setup_user_and_conn(%{conn: conn}) do
    user = Radiator.TestEntries.user()

    [
      conn: Radiator.TestEntries.put_current_user(conn, user),
      user: user
    ]
  end

  setup :setup_user_and_conn

  describe "episode creation flow" do
    test "create episode, audio, image and upload file", %{conn: conn, user: user} do
      podcast = insert(:podcast) |> publish() |> owned_by(user)

      # create episode
      conn =
        post(
          conn,
          Routes.api_episode_path(conn, :create),
          %{
            episode: %{title: "EP001", podcast_id: podcast.id}
          }
        )

      episode = json_response(conn, :created)
      assert %{"title" => "EP001"} = json_response(conn, :created)

      # create audio with image

      upload_image = %Plug.Upload{
        path: "test/fixtures/image.jpg",
        filename: "image.jpg"
      }

      conn =
        conn
        |> recycle()
        |> post(Routes.api_episode_audio_path(conn, :create, episode["id"]), %{
          audio: %{image: upload_image}
        })

      audio = json_response(conn, :created)
      assert %{"image" => audio_image} = json_response(conn, :created)
      assert audio_image

      # create audio file

      upload_audio_file = %Plug.Upload{
        path: "test/fixtures/pling.mp3",
        filename: "pling.mp3"
      }

      conn =
        conn
        |> recycle()
        |> post(Routes.api_audio_file_path(conn, :create, audio["id"]), %{
          audio_file: %{title: "ep001.mp3", mime_type: "audio/mpeg", file: upload_audio_file}
        })

      audio_file = json_response(conn, :created)
      assert %{"url" => audio_file_url} = json_response(conn, :created)
      assert audio_file_url
      assert audio_file

      # publish episode

      conn =
        conn
        |> recycle()
        |> put(Routes.api_episode_episode_path(conn, :publish, episode["id"]))

      assert response(conn, :no_content)

      # get episode

      conn =
        conn
        |> recycle()
        |> get(Routes.api_episode_path(conn, :show, episode["id"]))

      assert %{"publish_state" => "published", "published_at" => published_at, "slug" => slug} =
               json_response(conn, :ok)

      assert published_at
      assert slug
    end
  end
end
