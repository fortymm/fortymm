defmodule Fortymm.Matches.Match do
  @moduledoc """
  Embedded schema for a match.

  This schema represents an active or completed match between players, including:
  - `status`: Current state of the match (pending, in_progress, canceled, aborted, complete)
  - `match_configuration`: The configuration settings for this match
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.Matches.{Configuration, Participant}

  @valid_statuses ["pending", "in_progress", "canceled", "aborted", "complete"]

  embedded_schema do
    embeds_one :match_configuration, Configuration
    embeds_many :participants, Participant
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
    |> cast_embed(:participants)
    |> validate_required([:status])
    |> validate_inclusion(:status, @valid_statuses,
      message: "must be one of: #{Enum.join(@valid_statuses, ", ")}"
    )
    |> validate_participants_count()
  end

  defp validate_participants_count(changeset) do
    case get_field(changeset, :participants) do
      participants when is_list(participants) and length(participants) == 2 ->
        changeset

      participants when is_list(participants) ->
        add_error(
          changeset,
          :participants,
          "must have exactly 2 participants, got #{length(participants)}"
        )

      nil ->
        add_error(changeset, :participants, "must have exactly 2 participants")
    end
  end

  @doc """
  Returns the list of valid match statuses.

  ## Examples

      iex> valid_statuses()
      ["pending", "in_progress", "canceled", "aborted", "complete"]

  """
  def valid_statuses, do: @valid_statuses
end
