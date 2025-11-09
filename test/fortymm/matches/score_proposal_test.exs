defmodule Fortymm.Matches.ScoreProposalTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.ScoreProposal

  describe "changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 11},
            %{match_participant_id: 2, score: 9}
          ]
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :proposed_by_participant_id) == 1
      scores = Ecto.Changeset.get_field(changeset, :scores)
      assert length(scores) == 2
    end

    test "rejects single score" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 21}
          ]
        })

      refute changeset.valid?
      assert "must have exactly 2 scores" in errors_on(changeset).scores
    end

    test "accepts exactly 2 scores" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 2,
          scores: [
            %{match_participant_id: 1, score: 21},
            %{match_participant_id: 2, score: 19}
          ]
        })

      assert changeset.valid?
      scores = Ecto.Changeset.get_field(changeset, :scores)
      assert length(scores) == 2
    end

    test "accepts proposed_by_participant_id 2" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 2,
          scores: [
            %{match_participant_id: 1, score: 21},
            %{match_participant_id: 2, score: 19}
          ]
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :proposed_by_participant_id) == 2
    end

    test "requires proposed_by_participant_id" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          scores: [
            %{match_participant_id: 1, score: 21}
          ]
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).proposed_by_participant_id
    end

    test "requires scores" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).scores
    end

    test "rejects empty scores array" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: []
        })

      refute changeset.valid?
      assert "must have exactly 2 scores" in errors_on(changeset).scores
    end

    test "rejects more than 2 scores" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 21},
            %{match_participant_id: 2, score: 19},
            %{match_participant_id: 1, score: 15}
          ]
        })

      refute changeset.valid?
      assert "must have exactly 2 scores" in errors_on(changeset).scores
    end

    test "validates nested score changesets with invalid score" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: -5},
            %{match_participant_id: 2, score: 21}
          ]
        })

      refute changeset.valid?

      assert %{scores: [%{score: ["must be greater than or equal to 0"]}, _]} =
               errors_on(changeset)
    end

    test "validates all nested score changesets" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1},
            %{score: 21}
          ]
        })

      refute changeset.valid?
      errors = errors_on(changeset)

      assert %{
               scores: [%{score: ["can't be blank"]}, %{match_participant_id: ["can't be blank"]}]
             } = errors
    end

    test "treats nil proposed_by_participant_id as blank" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: nil,
          scores: [
            %{match_participant_id: 1, score: 21}
          ]
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).proposed_by_participant_id
    end

    test "treats nil scores as blank" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: nil
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).scores
    end

    test "accepts proposed_by_participant_id as string integer" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: "1",
          scores: [
            %{match_participant_id: 1, score: 21},
            %{match_participant_id: 2, score: 19}
          ]
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :proposed_by_participant_id) == 1
    end

    test "rejects non-integer proposed_by_participant_id" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: "invalid",
          scores: [
            %{match_participant_id: 1, score: 21}
          ]
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).proposed_by_participant_id
    end

    test "rejects float proposed_by_participant_id" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1.5,
          scores: [
            %{match_participant_id: 1, score: 21}
          ]
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).proposed_by_participant_id
    end

    test "does not cast unknown fields" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 21},
            %{match_participant_id: 2, score: 19}
          ],
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end

    test "accepts score with zero value for loser" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 11},
            %{match_participant_id: 2, score: 0}
          ]
        })

      assert changeset.valid?
    end

    test "propagates nested score validation errors" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 21},
            %{match_participant_id: "invalid", score: "not a number"}
          ]
        })

      refute changeset.valid?
      errors = errors_on(changeset)

      assert %{scores: [_, %{match_participant_id: ["is invalid"], score: ["is invalid"]}]} =
               errors
    end
  end

  describe "game scoring rules validation" do
    test "accepts valid 11-0 score" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 11},
            %{match_participant_id: 2, score: 0}
          ]
        })

      assert changeset.valid?
    end

    test "accepts valid 11-9 score" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 11},
            %{match_participant_id: 2, score: 9}
          ]
        })

      assert changeset.valid?
    end

    test "accepts valid 12-10 score (deuce scenario)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 12},
            %{match_participant_id: 2, score: 10}
          ]
        })

      assert changeset.valid?
    end

    test "accepts valid 15-13 score (extended deuce)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 15},
            %{match_participant_id: 2, score: 13}
          ]
        })

      assert changeset.valid?
    end

    test "accepts valid 13-15 score (second player wins)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 2,
          scores: [
            %{match_participant_id: 1, score: 13},
            %{match_participant_id: 2, score: 15}
          ]
        })

      assert changeset.valid?
    end

    test "rejects 10-8 score (neither player has 11)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 10},
            %{match_participant_id: 2, score: 8}
          ]
        })

      refute changeset.valid?
      assert "at least one player must have 11 or more points" in errors_on(changeset).scores
    end

    test "rejects 11-10 score (game must continue to 2-point lead)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 11},
            %{match_participant_id: 2, score: 10}
          ]
        })

      refute changeset.valid?

      assert "game cannot end 11-10 or higher, must continue until 2-point lead" in errors_on(
               changeset
             ).scores
    end

    test "rejects 10-11 score (game must continue to 2-point lead)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 2,
          scores: [
            %{match_participant_id: 1, score: 10},
            %{match_participant_id: 2, score: 11}
          ]
        })

      refute changeset.valid?

      assert "game cannot end 11-10 or higher, must continue until 2-point lead" in errors_on(
               changeset
             ).scores
    end

    test "rejects 12-11 score (need exactly 2-point lead)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 12},
            %{match_participant_id: 2, score: 11}
          ]
        })

      refute changeset.valid?
      assert "winner must have exactly a 2-point lead" in errors_on(changeset).scores
    end

    test "rejects 15-12 score (need exactly 2-point lead)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 1,
          scores: [
            %{match_participant_id: 1, score: 15},
            %{match_participant_id: 2, score: 12}
          ]
        })

      refute changeset.valid?
      assert "winner must have exactly a 2-point lead" in errors_on(changeset).scores
    end

    test "rejects 14-15 score (need exactly 2-point lead)" do
      changeset =
        ScoreProposal.changeset(%ScoreProposal{}, %{
          proposed_by_participant_id: 2,
          scores: [
            %{match_participant_id: 1, score: 14},
            %{match_participant_id: 2, score: 15}
          ]
        })

      refute changeset.valid?
      assert "winner must have exactly a 2-point lead" in errors_on(changeset).scores
    end
  end

  # Helper function to extract error messages
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
