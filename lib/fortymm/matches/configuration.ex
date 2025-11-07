defmodule Fortymm.Matches.Configuration do
  @moduledoc """
  Embedded schema for match configuration settings.

  This schema defines the configuration parameters for a match, including:
  - `length_in_games`: The number of games to be played (best-of format)
  - `rated`: Whether the match affects player ratings
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_lengths [1, 3, 5, 7]

  embedded_schema do
    field :length_in_games, :integer
    field :rated, :boolean, default: false
  end

  @doc """
  Creates a changeset for a Configuration.

  ## Examples

      iex> changeset(%Configuration{}, %{length_in_games: 3})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Configuration{}, %{length_in_games: 2})
      %Ecto.Changeset{valid?: false}

      iex> changeset(%Configuration{}, %{length_in_games: 5, rated: true})
      %Ecto.Changeset{valid?: true}

  """
  def changeset(configuration, attrs) do
    configuration
    |> cast(attrs, [:length_in_games, :rated])
    |> validate_required([:length_in_games])
    |> validate_inclusion(:length_in_games, @valid_lengths,
      message: "must be one of: #{Enum.join(@valid_lengths, ", ")}"
    )
  end

  @doc """
  Returns the list of valid game lengths.

  ## Examples

      iex> valid_lengths()
      [1, 3, 5, 7]

  """
  def valid_lengths, do: @valid_lengths
end
