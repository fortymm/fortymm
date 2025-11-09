defmodule Fortymm.Matches.Game do
  @moduledoc """
  Embedded schema for a game within a match.

  This schema represents an individual game in a match, including:
  - `id`: A unique identifier for the game (generated automatically)
  - `game_number`: The sequential number of the game (1, 2, 3, etc.)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  embedded_schema do
    field :game_number, :integer
  end

  @doc """
  Creates a changeset for a Game.

  ## Examples

      iex> changeset(%Game{}, %{game_number: 1})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Game{}, %{})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:game_number])
    |> validate_required([:game_number])
    |> validate_number(:game_number, greater_than: 0, message: "must be greater than 0")
  end
end
