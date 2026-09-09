defmodule Radiator.Podcasts.EmbeddedTest do
  use ExUnit.Case, async: true

  alias Radiator.Podcasts.Episode.Chapter
  alias Radiator.Podcasts.Episode.Transcript
  alias Radiator.Podcasts.Podcast.Category

  test "Chapter casts a list of maps" do
    assert {:ok, [%Chapter{start_ms: 0, title: "Intro"}, %Chapter{start_ms: 754_567}]} =
             Ash.Type.cast_input(
               {:array, Chapter},
               [%{start_ms: 0, title: "Intro"}, %{start_ms: 754_567, title: "Hauptteil"}],
               items: []
             )
  end

  test "Chapter requires start_ms" do
    assert {:error, _} = Ash.Type.cast_input(Chapter, %{title: "Ohne Start"}, [])
  end

  test "Transcript requires a URL" do
    assert {:ok, %Transcript{url: "https://example.com/e1.vtt", type: "text/vtt"}} =
             Ash.Type.cast_input(
               Transcript,
               %{url: "https://example.com/e1.vtt", type: "text/vtt"},
               []
             )

    assert {:error, _} = Ash.Type.cast_input(Transcript, %{type: "text/vtt"}, [])
  end

  test "Category requires text and allows a subcategory" do
    assert {:ok, %Category{text: "Technology", subcategory: nil}} =
             Ash.Type.cast_input(Category, %{text: "Technology"}, [])

    assert {:ok, %Category{subcategory: "Podcasting"}} =
             Ash.Type.cast_input(Category, %{text: "Technology", subcategory: "Podcasting"}, [])
  end
end
