defmodule Fortymm.Matches.Match do
  @moduledoc """
  Embedded schema for a match.

  This schema represents an active or completed match between players, including:
  - `status`: Current state of the match (pending, in_progress, canceled, aborted, complete)
  - `match_configuration`: The configuration settings for this match
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.Matches.Configuration

  @valid_statuses ["pending", "in_progress", "canceled", "aborted", "complete"]

  embedded_schema do
    embeds_one :match_configuration, Configuration
    field :status, :string, default: "pending"
  end

  @doc """
  Creates a changeset for a Match.

  ## Examples

      iex> changeset(%Match{}, %{status: "pending", match_configuration: %{length_in_games: 3}})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%Match{}, %{status: "invalid"})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:status])
    |> cast_embed(:match_configuration, required: true)
    |> validate_required([:status])
    |> validate_inclusion(:status, @valid_statuses,
      message: "must be one of: #{Enum.join(@valid_statuses, ", ")}"
    )
  end

  @doc """
  Returns the list of valid match statuses.

  ## Examples

      iex> valid_statuses()
      ["pending", "in_progress", "canceled", "aborted", "complete"]

  """
  def valid_statuses, do: @valid_statuses
end
