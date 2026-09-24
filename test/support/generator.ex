defmodule Radiator.Generator do
  @moduledoc """
  This module provides functions to generate and seed test data.
  """

  use Ash.Generator

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Person
  alias Radiator.Podcasts.Podcast

  def user(opts \\ []) do
    seed_generator(
      %User{email: sequence(:user_email, &"user#{&1}@example.com")},
      overrides: opts
    )
  end

  @doc "A podcast without any members; use `create_podcast` for one with an owner."
  def podcast(opts \\ []) do
    seed_generator(
      %Podcast{title: sequence(:podcast_title, &"Podcast #{&1}")},
      overrides: opts
    )
  end

  @doc "An episode. `podcast_id` has to be supplied by the caller."
  def episode(opts \\ []) do
    seed_generator(
      %Episode{
        title: sequence(:episode_title, &"Episode #{&1}"),
        guid: sequence(:episode_guid, &"item-#{&1}")
      },
      overrides: opts
    )
  end

  @doc "A person. `user_id` has to be supplied by the caller."
  def person(opts \\ []) do
    seed_generator(
      %Person{
        name: sequence(:person_name, &"Person #{&1}"),
        normalized_name: sequence(:person_normalized_name, &"person #{&1}")
      },
      overrides: opts
    )
  end
end
