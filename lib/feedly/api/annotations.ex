defmodule Feedly.API.Annotations do
  @moduledoc """
  API for article annotations (notes and highlights).
  """

  alias Feedly.{Client, Config}

  @doc """
  Adds annotations to articles.

  ## Annotation Structure

      %{
        entryIds: ["entry_id_1", "entry_id_2"],
        comment: "This is a note",
        highlight: %{
          version: 1,
          start: 100,
          end: 200,
          text: "highlighted text"
        }
      }

  ## Examples

      annotation = %{
        entryIds: ["entry_id"],
        comment: "Important finding"
      }

      {:ok, _} = Feedly.API.Annotations.create(client, annotation)

  """
  @spec create(Config.t(), map()) :: {:ok, term()} | {:error, term()}
  def create(%Config{} = config, annotation) do
    Client.post(config, "/annotations", annotation)
  end
end
