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
  end

  scope "/", RadiatorWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", RadiatorWeb do
    pipe_through :api

    resources "/podcasts", PodcastController, except: [:new, :edit] do
      resources "/episodes", EpisodeController, except: [:new, :edit] do
        post "/upload/:filename", UploadController, :create
      end
    end
  end
end
