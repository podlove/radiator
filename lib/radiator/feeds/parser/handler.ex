defmodule Radiator.Feeds.Parser.Handler do
  @moduledoc """
  A `Saxy.Handler` that turns a podcast feed into `Radiator.Feeds.Feed`.

  Saxy performs no namespace processing and hands element names over verbatim,
  prefix included. The handler therefore carries a stack of prefix tables that
  it pushes and pops around every element, and decides on the resolved
  namespace URI. Prefixes are free for a feed to choose, and feeds do rebind
  them partway through a document.

  Unknown elements are skipped rather than treated as errors.

  The clauses for item fields deliberately come **before** those for channel
  fields: names such as `itunes:subtitle` exist at both levels, and the channel
  clause would otherwise swallow the item case instead of letting it through.
  """

  @behaviour Saxy.Handler

  alias Radiator.Feeds.Feed
  alias Radiator.Feeds.Feed.Category
  alias Radiator.Feeds.Feed.Channel
  alias Radiator.Feeds.Feed.Chapter
  alias Radiator.Feeds.Feed.Enclosure
  alias Radiator.Feeds.Feed.Item
  alias Radiator.Feeds.Feed.Person
  alias Radiator.Feeds.Feed.Transcript
  alias Radiator.Feeds.Parser.Coercion

  @none ""
  @itunes "http://www.itunes.com/dtds/podcast-1.0.dtd"
  @podcast "https://podcastindex.org/namespace/1.0"
  @content "http://purl.org/rss/1.0/modules/content/"
  @psc "http://podlove.org/simple-chapters"
  @atom "http://www.w3.org/2005/Atom"

  # Elements that only ever hold other elements. Their own text is never read,
  # so the character data of their children is not bubbled up into them —
  # otherwise `<rss>` would end up holding a copy of the whole document.
  @containers [{@none, "rss"}, {@none, "channel"}, {@none, "item"}, {@psc, "chapters"}]

  @doc "The starting state for `Saxy.parse_string/4`."
  def initial_state do
    %{
      ns: [%{}],
      path: [],
      text: [[]],
      channel: %Channel{},
      items: [],
      item: nil,
      contributor: nil,
      attrs: %{}
    }
  end

  @doc """
  Builds the feed from the parser's final state.

  Categories are reversed because they are collected by prepending. Persons are
  not — `merge_person/2` appends, so that a second occurrence of the same
  person fills in the existing entry where it already sits.
  """
  def to_feed(state) do
    %Feed{
      channel: %{state.channel | categories: Enum.reverse(state.channel.categories)},
      items: Enum.reverse(state.items)
    }
  end

  @impl Saxy.Handler
  def handle_event(:start_document, _prolog, state), do: {:ok, state}

  def handle_event(:end_document, _data, state), do: {:ok, state}

  def handle_event(:start_element, {name, attributes}, state) do
    ns = [merge_namespaces(hd(state.ns), attributes) | state.ns]
    qname = resolve(name, hd(ns))
    state = %{state | ns: ns, path: [qname | state.path], text: [[] | state.text]}

    {:ok, start_element(qname, attributes, state)}
  end

  def handle_event(:end_element, _name, state) do
    [qname | rest] = state.path
    [text | outer] = state.text
    state = end_element(qname, IO.iodata_to_binary(text), state)

    {:ok, %{state | path: rest, ns: tl(state.ns), text: bubble(text, hd_or_nil(rest), outer)}}
  end

  def handle_event(:characters, chars, state), do: {:ok, buffer(state, chars)}

  def handle_event(:cdata, chars, state), do: {:ok, buffer(state, chars)}

  defp buffer(state, chars) do
    [current | outer] = state.text

    %{state | text: [[current, chars] | outer]}
  end

  # The character data of a child belongs to the parent's text as well. Without
  # this, `<description>Some <b>bold</b> text</description>` would yield only
  # the run after the last child element — a silently truncated value rather
  # than an error.
  defp bubble(_text, _parent, []), do: []
  defp bubble(_text, parent, outer) when parent in @containers, do: outer
  defp bubble(text, _parent, [current | outer]), do: [[current, text] | outer]

  defp hd_or_nil([head | _rest]), do: head
  defp hd_or_nil([]), do: nil

  defp merge_namespaces(current, attributes) do
    Enum.reduce(attributes, current, fn
      {"xmlns:" <> prefix, uri}, acc -> Map.put(acc, prefix, uri)
      _other, acc -> acc
    end)
  end

  defp resolve(name, prefixes) do
    case String.split(name, ":", parts: 2) do
      [local] -> {@none, local}
      [prefix, local] -> {Map.get(prefixes, prefix, prefix), local}
    end
  end

  defp parent(%{path: [_current, parent | _rest]}), do: parent
  defp parent(_state), do: nil

  # --- start_element: persons (both levels) --------------------------------

  # Elements that carry attributes *and* text: the attributes are only available
  # here, the text only on the closing tag, so they are parked in `attrs`.
  defp start_element({@podcast, name}, attributes, state)
       when name in ~w(person funding license) do
    %{state | attrs: Map.new(attributes)}
  end

  defp start_element({@atom, "contributor"}, _attributes, state) do
    %{state | contributor: %Person{}}
  end

  # --- start_element: item -------------------------------------------------

  defp start_element({@none, "item"}, _attributes, state), do: %{state | item: %Item{}}

  defp start_element({@none, "enclosure"}, attributes, %{item: %Item{}} = state) do
    enclosure = %Enclosure{
      url: attribute(attributes, "url"),
      length: Coercion.integer(attribute(attributes, "length")),
      type: attribute(attributes, "type")
    }

    put_item(state, :enclosure, enclosure)
  end

  defp start_element({@itunes, "image"}, attributes, %{item: %Item{}} = state) do
    put_item(state, :image_url, attribute(attributes, "href"))
  end

  defp start_element({@psc, "chapter"}, attributes, %{item: %Item{}} = state) do
    chapter = %Chapter{
      start_ms: Coercion.npt_ms(attribute(attributes, "start")),
      title: attribute(attributes, "title"),
      href: attribute(attributes, "href"),
      image_url: attribute(attributes, "image")
    }

    put_item(state, :chapters, [chapter | state.item.chapters])
  end

  defp start_element({@podcast, "chapters"}, attributes, %{item: %Item{}} = state) do
    state
    |> put_item(:chapters_url, attribute(attributes, "url"))
    |> put_item(:chapters_type, attribute(attributes, "type"))
  end

  defp start_element({@podcast, "transcript"}, attributes, %{item: %Item{}} = state) do
    transcript = %Transcript{
      url: attribute(attributes, "url"),
      type: attribute(attributes, "type"),
      language: attribute(attributes, "language"),
      rel: attribute(attributes, "rel")
    }

    put_item(state, :transcripts, [transcript | state.item.transcripts])
  end

  # --- start_element: channel ----------------------------------------------

  defp start_element({@itunes, "image"}, attributes, state) do
    maybe_channel(state, :image_url, attribute(attributes, "href"))
  end

  # A nested `itunes:category` is the subcategory of the one just opened.
  defp start_element({@itunes, "category"}, attributes, state) do
    text = attribute(attributes, "text")

    case {parent(state), state.channel.categories} do
      {{@none, "channel"}, categories} ->
        put_categories(state, [%Category{text: text} | categories])

      {{@itunes, "category"}, [current | rest]} ->
        put_categories(state, [%{current | subcategory: text} | rest])

      _other ->
        state
    end
  end

  defp start_element(_qname, _attributes, state), do: state

  # --- end_element: persons (both levels) ----------------------------------

  defp end_element({@podcast, "person"}, text, state) do
    person = %Person{
      name: text,
      role: normalize_role(Map.get(state.attrs, "role")),
      image_url: Map.get(state.attrs, "img")
    }

    state |> add_person(person) |> Map.put(:attrs, %{})
  end

  defp end_element({@atom, "name"}, text, %{contributor: %Person{}} = state) do
    %{state | contributor: %{state.contributor | name: text}}
  end

  defp end_element({@atom, "uri"}, text, %{contributor: %Person{}} = state) do
    %{state | contributor: %{state.contributor | uri: text}}
  end

  defp end_element({@atom, "contributor"}, _text, %{contributor: %Person{} = person} = state) do
    state |> add_person(person) |> Map.put(:contributor, nil)
  end

  # --- end_element: item ---------------------------------------------------

  # Chapters and transcripts are collected by prepending.
  defp end_element({@none, "item"}, _text, %{item: item} = state) do
    item = %{
      item
      | chapters: Enum.reverse(item.chapters),
        transcripts: Enum.reverse(item.transcripts)
    }

    %{state | items: [item | state.items], item: nil}
  end

  defp end_element({@none, field}, text, %{item: %Item{}} = state)
       when field in ~w(title link guid description) do
    maybe_item(state, String.to_existing_atom(field), text)
  end

  defp end_element({@none, "pubDate"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :published_at, Coercion.datetime(text))
  end

  defp end_element({@content, "encoded"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :content_html, text)
  end

  defp end_element({@itunes, "title"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :itunes_title, text)
  end

  defp end_element({@itunes, "subtitle"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :subtitle, text)
  end

  defp end_element({@itunes, "summary"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :itunes_summary, text)
  end

  defp end_element({@itunes, "author"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :author, text)
  end

  defp end_element({@itunes, "episode"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :number, Coercion.integer(text))
  end

  defp end_element({@itunes, "season"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :season, Coercion.integer(text))
  end

  defp end_element({@itunes, "episodeType"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :episode_type, text)
  end

  defp end_element({@itunes, "duration"}, text, %{item: %Item{}} = state) do
    maybe_item(state, :duration_seconds, Coercion.duration_seconds(text))
  end

  # --- end_element: channel ------------------------------------------------

  defp end_element({@none, field}, text, state)
       when field in ~w(title link description language copyright) do
    maybe_channel(state, String.to_existing_atom(field), text)
  end

  defp end_element({@itunes, "author"}, text, state), do: maybe_channel(state, :author, text)
  defp end_element({@itunes, "subtitle"}, text, state), do: maybe_channel(state, :subtitle, text)
  defp end_element({@itunes, "summary"}, text, state), do: maybe_channel(state, :summary, text)

  defp end_element({@podcast, "funding"}, text, state) do
    state
    |> maybe_channel(:funding_url, Map.get(state.attrs, "url"))
    |> maybe_channel(:funding_text, text)
    |> Map.put(:attrs, %{})
  end

  defp end_element({@podcast, "license"}, text, state) do
    state
    |> maybe_channel(:license_url, Map.get(state.attrs, "url"))
    |> maybe_channel(:license, text)
    |> Map.put(:attrs, %{})
  end

  defp end_element({@itunes, "type"}, text, state), do: maybe_channel(state, :podcast_type, text)
  defp end_element({@podcast, "guid"}, text, state), do: maybe_channel(state, :guid, text)

  defp end_element({@itunes, "explicit"}, text, state) do
    maybe_channel(state, :explicit, Coercion.boolean(text))
  end

  defp end_element({@itunes, "name"}, text, %{path: [_, {@itunes, "owner"} | _]} = state) do
    put_channel(state, :owner_name, text)
  end

  defp end_element({@itunes, "email"}, text, %{path: [_, {@itunes, "owner"} | _]} = state) do
    put_channel(state, :owner_email, text)
  end

  defp end_element(_qname, _text, state), do: state

  # --- merging persons -----------------------------------------------------

  defp add_person(state, %Person{name: name}) when name in [nil, ""], do: state

  defp add_person(%{item: %Item{}} = state, person) do
    put_item(state, :persons, merge_person(state.item.persons, person))
  end

  defp add_person(state, person) do
    %{state | channel: %{state.channel | persons: merge_person(state.channel.persons, person)}}
  end

  defp merge_person(persons, person) do
    key = normalize_name(person.name)

    case Enum.find_index(persons, &(normalize_name(&1.name) == key)) do
      nil -> persons ++ [person]
      index -> List.update_at(persons, index, &fill_person(&1, person))
    end
  end

  defp fill_person(existing, incoming) do
    %Person{
      name: existing.name,
      role: incoming.role || existing.role,
      image_url: incoming.image_url || existing.image_url,
      uri: incoming.uri || existing.uri
    }
  end

  defp normalize_name(name), do: name |> String.trim() |> String.downcase()

  defp normalize_role(nil), do: nil
  defp normalize_role(role), do: role |> String.trim() |> String.downcase()

  # --- state helpers -------------------------------------------------------

  defp put_categories(state, categories) do
    %{state | channel: %{state.channel | categories: categories}}
  end

  defp maybe_channel(state, field, value) do
    if parent(state) == {@none, "channel"}, do: put_channel(state, field, value), else: state
  end

  defp put_channel(state, _field, value) when value in [nil, ""], do: state

  defp put_channel(state, field, value) do
    %{state | channel: Map.put(state.channel, field, value)}
  end

  defp maybe_item(state, field, value) do
    if parent(state) == {@none, "item"}, do: put_item(state, field, value), else: state
  end

  defp put_item(state, _field, value) when value in [nil, ""], do: state

  defp put_item(state, field, value), do: %{state | item: Map.put(state.item, field, value)}

  defp attribute(attributes, name) do
    Enum.find_value(attributes, fn
      {^name, value} -> value
      _other -> nil
    end)
  end
end
