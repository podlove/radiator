defmodule RadiatorWeb.Router do
  use RadiatorWeb, :router

  pipeline :browser do
    plug RadiatorWeb.Plug.BlockKnownPaths
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :public_browser do
    plug RadiatorWeb.Plug.BlockKnownPaths
    plug :accepts, ["html", "xml", "rss"]
    plug :put_secure_browser_headers

    plug :put_layout, {RadiatorWeb.LayoutView, :public}

    plug RadiatorWeb.Plug.AssignFromPublicSlugs
  end

  @otp_app Mix.Project.config()[:app]

  pipeline :authenticated_browser do
    plug Guardian.Plug.Pipeline,
      otp_app: @otp_app,
      module: Radiator.Auth.Guardian,
      error_handler: RadiatorWeb.GuardianErrorHandler

    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource

    plug RadiatorWeb.Plug.EnsureUserValidity
    plug RadiatorWeb.Plug.AssignCurrentAdminResources
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug RadiatorWeb.Plug.ValidateAPIUser
  end

  pipeline :authenticated_api do
    plug Guardian.Plug.Pipeline,
      otp_app: @otp_app,
      module: Radiator.Auth.Guardian,
      error_handler: RadiatorWeb.GuardianApiErrorHandler

    plug Guardian.Plug.VerifySession, claims: %{"typ" => "api_session"}
    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "api_session"}
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource

    plug RadiatorWeb.Plug.AssignCurrentUser
  end

  scope "/admin", RadiatorWeb.Admin, as: :admin do
    pipe_through :browser
    pipe_through :authenticated_browser

    resources "/networks", NetworkController do
      resources "/collaborators", CollaboratorController, only: [:create, :update, :delete]

      resources "/podcasts", PodcastController do
        resources "/collaborators", CollaboratorController, only: [:create, :update, :delete]

        resources "/episodes", EpisodeController
      end

      resources "/import", PodcastImportController, only: [:new, :create]
    end

    get "/usersettings", UserSettingsController, :index
    post "/usersettings", UserSettingsController, :update
    put "/usersettings", UserSettingsController, :update
  end

  scope "/download", RadiatorWeb do
    get "/audio/:id", TrackingController, :show
  end

  scope "/api/rest/v1", RadiatorWeb.Api, as: :api do
    pipe_through :api

    post "/auth", AuthenticationController, :create
  end

  scope "/api/rest/v1", RadiatorWeb.Api, as: :api do
    pipe_through [:api, :authenticated_api]

    post "/auth/prolong", AuthenticationController, :prolong

    resources "/networks", NetworkController, only: [:show, :create, :update, :delete] do
      resources "/collaborators", CollaboratorController, only: [:show, :create, :update, :delete]
      resources "/audios", AudioController, only: [:create]
    end

    resources "/podcasts", PodcastController, only: [:show, :create, :update, :delete] do
      resources "/collaborators", CollaboratorController, only: [:show, :create, :update, :delete]
    end

    resources "/episodes", EpisodeController, only: [:show, :create, :update, :delete] do
      resources "/audios", AudioController, only: [:create]
    end

    resources "/audio_publications", AudioPublicationController,
      only: [:index, :show, :update, :delete]

    resources "/people", PersonController, only: [:index, :show, :create, :update, :delete]

    resources "/audios", AudioController, only: [:show, :update, :delete] do
      resources "/audio_files", AudioFileController,
        only: [:index, :create],
        as: :file

      resources "/chapters", ChaptersController,
        param: "start",
        only: [:show, :create, :update, :delete]
    end

    resources "/audio_files", AudioFileController, only: [:show, :update, :delete]

    resources "/contributions", ContributionController,
      only: [:index, :show, :create, :update, :delete]

    resources "/tasks", TaskController, only: [:show, :create, :delete]
  end

  scope "/api" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug, schema: RadiatorWeb.GraphQL.Schema
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: RadiatorWeb.GraphQL.Schema
  end

  scope "/", RadiatorWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/audio/:audio_id/player.json", PlayerController, :audio_config
    get "/episode/:episode_id/player.json", PlayerController, :episode_config

    get "/login/request_verification/:token", LoginController, :resend_verification_mail
    get "/login/verify_email/:token", LoginController, :verify_email

    get "/login", LoginController, :index
    post "/login", LoginController, :login

    get "/login_form", LoginController, :login_form

    get "/signup", LoginController, :signup_form
    post "/signup", LoginController, :signup

    get "/logout", LoginController, :logout
  end

  scope "/", RadiatorWeb.Public do
    pipe_through :public_browser

    get "/:podcast_slug/feed.xml", FeedController, :show
    get "/:podcast_slug/:episode_slug", EpisodeController, :show
    get "/:podcast_slug", EpisodeController, :index
  end
end
