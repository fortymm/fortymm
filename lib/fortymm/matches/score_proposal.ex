defmodule Fortymm.Matches.ScoreProposal do
  @moduledoc """
  Embedded schema for a score proposal within a game.

  This schema represents a proposed score for a game, including:
  - `scores`: A collection of scores for each participant
  - `proposed_by_participant_id`: The participant ID who proposed this score
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :proposed_by_participant_id, :integer

    embeds_many :scores, Fortymm.Matches.Score
  end

  @doc """
  Creates a changeset for a ScoreProposal.

  ## Examples

      iex> changeset(%ScoreProposal{}, %{proposed_by_participant_id: 1, scores: [%{match_participant_id: 1, score: 21}]})
      %Ecto.Changeset{valid?: true}

      iex> changeset(%ScoreProposal{}, %{})
      %Ecto.Changeset{valid?: false}

  """
  def changeset(score_proposal, attrs) do
    score_proposal
    |> cast(attrs, [:proposed_by_participant_id])
    |> cast_embed(:scores, required: true)
    |> validate_required([:proposed_by_participant_id])
    |> validate_scores_count()
    |> validate_game_scoring_rules()
  end

  defp validate_scores_count(changeset) do
    case Ecto.Changeset.get_field(changeset, :scores) do
      scores when is_list(scores) and length(scores) == 2 ->
        changeset

      _ ->
        Ecto.Changeset.add_error(changeset, :scores, "must have exactly 2 scores")
    end
  end

  defp validate_game_scoring_rules(changeset) do
    case Ecto.Changeset.get_field(changeset, :scores) do
      [score1, score2] when is_map(score1) and is_map(score2) ->
        validate_winning_score(changeset, score1.score, score2.score)

      _ ->
        changeset
    end
  end

  defp validate_winning_score(changeset, score1, score2)
       when is_integer(score1) and is_integer(score2) do
    max_score = max(score1, score2)
    min_score = min(score1, score2)
    diff = max_score - min_score

    cond do
      # At least one player must reach 11 points to win
      max_score < 11 ->
        Ecto.Changeset.add_error(
          changeset,
          :scores,
          "at least one player must have 11 or more points"
        )

      # If winner has exactly 11, opponent must have 9 or fewer (can't be 10-11 or 11-10)
      max_score == 11 and min_score >= 10 ->
        Ecto.Changeset.add_error(
          changeset,
          :scores,
          "game cannot end 11-10 or higher, must continue until 2-point lead"
        )

      # If winner has more than 11 (deuce situation), must win by exactly 2
      max_score > 11 and diff != 2 ->
        Ecto.Changeset.add_error(
          changeset,
          :scores,
          "winner must have exactly a 2-point lead"
        )

      true ->
        changeset
    end
  end

  defp validate_winning_score(changeset, _, _), do: changeset
end
