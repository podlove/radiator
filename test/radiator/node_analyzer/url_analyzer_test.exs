defmodule Radiator.NodeAnalyzer.UrlAnalyzerTest do
  use Radiator.DataCase

  alias Radiator.NodeAnalyzer.UrlAnalyzer

  describe "extract_url_positions/1" do
    test "recognizes an URL" do
      assert [%{start_bytes: 0, size_bytes: 22}] = UrlAnalyzer.analyze("https://www.google.com")
    end

    test "recognizes an URL with text behind" do
      assert [%{start_bytes: 0, size_bytes: 51}] =
               UrlAnalyzer.analyze("https://www.youtube.com/watch?v=kBU4v609DOU&t=1268s foo")
    end

    test "recognizes an URL with text before" do
      assert [%{start_bytes: 4, size_bytes: 35}] =
               UrlAnalyzer.analyze("bar https://github.com/podlove/radiator")
    end

    test "extracts urls in text" do
      assert [%{start_bytes: 24, size_bytes: 78}, %{start_bytes: 116, size_bytes: 43}] =
               UrlAnalyzer.analyze(
                 "das ist eine super URL: https://www.freecodecamp.org/news/how-to-write-a-regular-expression-for-a-url/ und das auch https://hexdocs.pm/elixir/Regex.html#scan/3"
               )
    end
  end
end
