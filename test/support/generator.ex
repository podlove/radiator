defmodule Radiator.Generator do
  @moduledoc """
  This module provides functions to generate and seed test data.
  """

  use Ash.Generator

  alias Faker.{Company, Internet, Lorem}

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
        first_name: StreamData.repeatedly(&Faker.Person.first_name/0),
        last_name: StreamData.repeatedly(&Faker.Person.last_name/0),
        display_name: StreamData.repeatedly(&Faker.Person.name/0),
        homepage_url: StreamData.repeatedly(&Internet.url/0),
        wikipedia_url: StreamData.repeatedly(&Internet.url/0),
        bio: StreamData.repeatedly(&Lorem.sentence/0)
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
        email: StreamData.repeatedly(&Internet.email/0),
        handle: StreamData.repeatedly(&Internet.user_name/0)
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
        title: StreamData.repeatedly(&Company.En.name/0),
        summary: StreamData.repeatedly(&Lorem.sentence/0)
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
        title: StreamData.repeatedly(&Lorem.sentence/0),
        summary: StreamData.repeatedly(&Lorem.sentence/0),
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
