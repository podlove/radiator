defmodule RadiatorWeb.Router do
  use RadiatorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  scope "/", RadiatorWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/feed/:podcast_id", FeedController, :show
  end

  scope "/admin", RadiatorWeb.Admin, as: :admin do
    pipe_through :browser

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
