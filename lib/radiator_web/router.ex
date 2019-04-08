defmodule RadiatorWeb.Router do
  use RadiatorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  scope "/", RadiatorWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/feed/:podcast_id", FeedController, :show

    get "/login/request_verification/:token", LoginController, :resend_verification_mail
    get "/login/verify_email/:token", LoginController, :verify_email

    get "/login", LoginController, :index
    post "/login", LoginController, :login

    get "/login_form", LoginController, :login_form

    get "/signup", LoginController, :signup_form
    post "/signup", LoginController, :signup

    get "/logout", LoginController, :logout
  end

  scope "/admin", RadiatorWeb.Admin, as: :admin do
    pipe_through :browser

    pipe_through :authenticated_browser

    resources "/podcasts", PodcastController do
      resources "/episodes", EpisodeController
    end

    resources "/import", PodcastImportController, only: [:new, :create]
  end

  # Other scopes may use custom stacks.
  scope "/api/rest/v1", RadiatorWeb.Api, as: :api do
    pipe_through :api

    resources "/upload", UploadController, only: [:create]
    resources "/files", FileController, only: [:index, :show]

    resources "/podcasts", PodcastController, except: [:new, :edit] do
      resources "/episodes", EpisodeController, except: [:new, :edit]
    end
  end

  scope "/api" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug, schema: RadiatorWeb.Schema
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: RadiatorWeb.Schema
  end
end
