defmodule Radiator.Feed.Common do
  import XmlBuilder
  import Radiator.Feed.Builder, only: [add: 2]

  alias Radiator.Contribution.{Person, Role}

  def contributor(%{person: person, role: role}) do
    element(
      :"atom:contributor",
      [element(:"atom:name", person.display_name)]
      |> add(contributor_uri(person))
      |> add(contributor_role(role))
    )
  end

  def contributor_uri(%Person{link: uri}) when byte_size(uri) > 0,
    do: element(:"atom:uri", uri)

  def contributor_uri(_), do: nil

  def contributor_role(%Role{title: title}) when byte_size(title) > 0,
    do: element(:"atom:role", title)

  def contributor_role(_), do: nil
end
