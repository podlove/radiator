defmodule Radiator.Generator do
  @moduledoc """
  This module provides functions to generate and seed test data.
  """

  use Ash.Generator

  alias Faker.{Company, Internet, Lorem, Phone}

  alias Radiator.People.Person
  alias Radiator.People.Persona
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Podcast

  def person(attrs \\ %{}) do
    changeset_generator(
      Person,
      :create,
      defaults: [
        real_name: StreamData.repeatedly(&Faker.Person.name/0),
        email: StreamData.repeatedly(&Internet.email/0),
        nickname: StreamData.repeatedly(&Internet.user_name/0),
        telephone: StreamData.repeatedly(&Phone.EnGb.number/0)
      ],
      overrides: attrs,
      authorize: false,
      actor: attrs[:actor]
    )
  end

  def persona(attrs \\ %{}) do
    person_id = Map.get(attrs, :person_id, generate(person()).id)

    changeset_generator(
      Persona,
      :create,
      defaults: [
        public_name: StreamData.repeatedly(&Internet.user_name/0),
        handle: StreamData.repeatedly(&Internet.user_name/0),
        description: StreamData.repeatedly(&Lorem.sentence/0),
        person_id: person_id
      ],
      overrides: attrs,
      authorize: false,
      actor: attrs[:actor]
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
end
