defmodule Fortymm.Matches.Challenge do
  @moduledoc """
  Embedded schema for a challenge.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_lengths [1, 3, 5, 7]

  embedded_schema do
    field :length_in_games, :integer
    field :rated, :boolean, default: false
    field :created_by_id, :integer
  end

  @doc """
  Creates a changeset for a Challenge.

  ## Examples

      iex> changeset(%Challenge{}, %{length_in_games: 3})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Challenge{}, %{length_in_games: 2})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(challenge, attrs) do
    challenge
    |> cast(attrs, [:length_in_games, :rated, :created_by_id])
    |> validate_required([:length_in_games, :created_by_id])
    |> validate_inclusion(:length_in_games, @valid_lengths,
      message: "must be one of: #{Enum.join(@valid_lengths, ", ")}"
    )
  end
end
