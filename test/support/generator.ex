defmodule Radiator.Generator do
  @moduledoc """
  This module provides functions to generate and seed test data.
  """

  use Ash.Generator

  alias Radiator.Podcasts.{Episode, Podcast}

  def podcast(opts \\ []) do
    changeset_generator(
      Podcast,
      :create,
      defaults: [
        title: StreamData.repeatedly(&Faker.Lorem.sentence(&1, 1..3)),
        summary: StreamData.repeatedly(&Faker.Lorem.sentence(&1, 3..6))
      ],
      overrides: opts,
      actor: opts[:actor]
    )
  end

  def episode(podcast_id, opts \\ []) do
    changeset_generator(
      Episode,
      :create,
      defaults: [
        title: StreamData.repeatedly(&Faker.Lorem.sentence(&1, 1..3)),
        summary: StreamData.repeatedly(&Faker.Lorem.sentence(&1, 3..6)),
        podcast_id: podcast_id
      ],
      overrides: opts,
      actor: opts[:actor]
    )
  end
end
