defmodule Fortymm.Matches.Score do
  @moduledoc """
  Embedded schema for a score within a score proposal.

  This schema represents a score for a specific participant in a game, including:
  - `match_participant_id`: Reference to the participant's embedded ID
  - `score`: The numeric score value for this participant
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :match_participant_id, :integer
    field :score, :integer
  end

  @doc """
  Creates a changeset for a Score.

  ## Examples

      iex> changeset(%Score{}, %{match_participant_id: 1, score: 21})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Score{}, %{})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:match_participant_id, :score])
    |> validate_required([:match_participant_id, :score])
    |> validate_number(:score,
      greater_than_or_equal_to: 0,
      message: "must be greater than or equal to 0"
    )
  end
end
