defmodule Fortymm.Matches.Participant do
  @moduledoc """
  Embedded schema for a match participant.

  This schema represents a player participating in a match, including:
  - `user_id`: The ID of the user participating in the match
  - `participant_number`: The participant number (1 or 2) for ordering
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :user_id, :integer
    field :participant_number, :integer
  end

  @doc """
  Creates a changeset for a Participant.

  ## Examples

      iex> changeset(%Participant{}, %{user_id: 1, participant_number: 1})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Participant{}, %{})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:user_id, :participant_number])
    |> validate_required([:user_id, :participant_number])
    |> validate_inclusion(:participant_number, [1, 2], message: "must be 1 or 2")
  end
end
