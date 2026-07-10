defmodule Radiator.Generator do
  @moduledoc """
  This module provides functions to generate and seed test data.
  """

  use Ash.Generator

  alias Radiator.Accounts.User
  alias Radiator.People.Person
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling
  alias Radiator.Podcasts.Podcast

  def person(attrs \\ %{}) do
    changeset_generator(
      Person,
      :create,
      defaults: [
        first_name: StreamData.repeatedly(fn -> "John#{System.unique_integer([:positive])}" end),
        last_name: StreamData.repeatedly(fn -> "Doe#{System.unique_integer([:positive])}" end),
        display_name:
          StreamData.repeatedly(fn -> "jonny#{System.unique_integer([:positive])}" end),
        homepage_url:
          StreamData.repeatedly(fn ->
            "https://www.example-#{System.unique_integer([:positive])}.com"
          end),
        wikipedia_url:
          StreamData.repeatedly(fn ->
            "https://www.wiki-#{System.unique_integer([:positive])}.com"
          end),
        bio: StreamData.repeatedly(fn -> "Lorem Ipsum #{System.unique_integer([:positive])}" end)
      ],
      overrides: attrs,
      authorize: false,
      actor: attrs[:actor]
    )
  end

  @doc """
  Generates a passwordless `User` (the actor/participant in scheduling).

  Pass `:handle` and/or `:email` as overrides. A `:person_id` override links the
  user to a `Person` via the `:update_profile` action.
  """
  def user(attrs \\ %{}) do
    person_id = Map.get(attrs, :person_id)

    changeset_generator(
      User,
      :invite_by_email,
      defaults: [
        email:
          StreamData.repeatedly(fn ->
            "user-#{System.unique_integer([:positive])}@example.com"
          end),
        handle: StreamData.repeatedly(fn -> "user-#{System.unique_integer([:positive])}" end)
      ],
      overrides: Map.drop(attrs, [:person_id]),
      authorize: false,
      actor: attrs[:actor],
      after_action: fn user ->
        if person_id do
          user
          |> Ash.Changeset.for_update(:update_profile, %{person_id: person_id}, authorize?: false)
          |> Ash.update!()
        else
          user
        end
      end
    )
  end

  def podcast(attrs \\ %{}) do
    changeset_generator(
      Podcast,
      :create,
      defaults: [
        title: StreamData.repeatedly(fn -> "Podcast-#{System.unique_integer([:positive])}" end),
        summary:
          StreamData.repeatedly(fn -> "Lorem Ipsum#{System.unique_integer([:positive])}" end)
      ],
      overrides: attrs,
      authorize: false,
      actor: attrs[:actor]
    )
  end

  def episode(attrs \\ %{}) do
    podcast_id = Map.get(attrs, :podcast_id, generate(podcast()).id)

    changeset_generator(
      Episode,
      :create,
      defaults: [
        title: StreamData.repeatedly(fn -> "Episode-#{System.unique_integer([:positive])}" end),
        summary:
          StreamData.repeatedly(fn -> "Lorem Ipsum #{System.unique_integer([:positive])}" end),
        podcast_id: podcast_id
      ],
      overrides: attrs,
      authorize: false,
      actor: attrs[:actor]
    )
  end

  def episode_scheduling(attrs \\ %{}) do
    episode_id = Map.get(attrs, :episode_id, generate(episode()).id)

    changeset_generator(
      Scheduling,
      :create,
      defaults: [
        podcast_id: episode_id
      ],
      overrides: attrs,
      authorize: false,
      actor: attrs[:actor]
    )
  end
end
