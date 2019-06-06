# Container to import for all images that are cover style, e.g. square and have a square 256x256 thumbnail representation
defmodule Radiator.Media.CoverImageBase do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @versions [:original, :thumbnail]

      def transform(:thumbnail, _) do
        {:convert, "-thumbnail 256x256^ -gravity center -extent 256x256 -format png", :png}
      end

      def s3_object_headers(_version, {file, _subject}) do
        [content_type: MIME.from_path(file.file_name)]
      end
    end
  end
end
