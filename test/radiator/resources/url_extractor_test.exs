defmodule Radiator.Resources.UrlExtractorTest do
  use Radiator.DataCase

  alias Radiator.Resources.UrlExtractor

  describe "extract_url_positions/1" do
    test "recognizes an URL" do
      assert UrlExtractor.extract_url_positions("https://www.google.com") ==
               [{0, 22}]
    end

    test "recognizes an URL with text behind" do
      assert UrlExtractor.extract_url_positions(
               "https://www.youtube.com/watch?v=kBU4v609DOU&t=1268s foo"
             ) ==
               [{0, 51}]
    end

    test "recognizes an URL with text before" do
      assert UrlExtractor.extract_url_positions("bar https://github.com/podlove/radiator") ==
               [{4, 35}]
    end

    test "extracts urls in text" do
      assert UrlExtractor.extract_url_positions(
               "das ist eine super URL: https://www.freecodecamp.org/news/how-to-write-a-regular-expression-for-a-url/ und das auch https://hexdocs.pm/elixir/Regex.html#scan/3"
             ) ==
               [{24, 78}, {116, 41}]
    end
  end
end
