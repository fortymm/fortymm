defmodule Fortymm.Matches.ScoreEntry do
  @moduledoc """
  Embedded schema for entering a score for a game.

  This schema validates a score entry for a specific game, ensuring:
  - `game_id`: The game this score entry is for
  - `score_proposal`: The proposed score with all its validations
  - The game doesn't already have a confirmed score
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :game_id, :string

    embeds_one :score_proposal, Fortymm.Matches.ScoreProposal
  end

  @doc """
  Creates a changeset for a ScoreEntry for validation during form filling.

  This is more lenient than the submission changeset, allowing partial data.
  """
  def changeset(score_entry, attrs) do
    score_entry
    |> cast(attrs, [:game_id])
    |> cast_embed(:score_proposal)
    |> validate_required([:game_id])
  end

  @doc """
  Creates a strict changeset for submission that requires all fields.

  ## Examples

      iex> changeset_for_submission(%ScoreEntry{}, %{game_id: "abc123", score_proposal: %{...}})
      %Ecto.Changeset{valid?: true}

      iex> changeset_for_submission(%ScoreEntry{}, %{})
      %Ecto.Changeset{valid?: false}

  """
  def changeset_for_submission(score_entry, attrs) do
    score_entry
    |> cast(attrs, [:game_id])
    |> cast_embed(:score_proposal, required: true)
    |> validate_required([:game_id])
  end

  @doc """
  Creates a changeset for a ScoreEntry with game validation.

  This version checks if the game already has a score by looking at the game's
  score_proposals list. Uses lenient validation for form filling.

  ## Parameters

    - `score_entry`: The ScoreEntry struct
    - `attrs`: The attributes map
    - `game`: The Game struct to validate against (optional)

  ## Examples

      iex> changeset_with_game(%ScoreEntry{}, %{...}, game)
      %Ecto.Changeset{valid?: true}

  """
  def changeset_with_game(score_entry, attrs, game \\ nil) do
    score_entry
    |> changeset(attrs)
    |> validate_game_has_no_score(game)
  end

  @doc """
  Creates a strict changeset for submission with game validation.

  Requires all fields to be present.
  """
  def changeset_with_game_for_submission(score_entry, attrs, game \\ nil) do
    score_entry
    |> changeset_for_submission(attrs)
    |> validate_game_has_no_score(game)
  end

  defp validate_game_has_no_score(changeset, nil), do: changeset

  defp validate_game_has_no_score(changeset, game) do
    case game.score_proposals do
      proposals when is_list(proposals) and length(proposals) > 0 ->
        Ecto.Changeset.add_error(
          changeset,
          :game_id,
          "game already has a confirmed score"
        )

      _ ->
        changeset
    end
  end
end
