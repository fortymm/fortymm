defmodule Fortymm.Matches.ScoreTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.Score

  describe "changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: 21
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :match_participant_id) == 1
      assert Ecto.Changeset.get_field(changeset, :score) == 21
    end

    test "accepts score of 0" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: 0
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :score) == 0
    end

    test "accepts large score values" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: 999
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :score) == 999
    end

    test "accepts match_participant_id 2" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 2,
          score: 15
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :match_participant_id) == 2
    end

    test "requires match_participant_id" do
      changeset = Score.changeset(%Score{}, %{score: 21})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).match_participant_id
    end

    test "requires score" do
      changeset = Score.changeset(%Score{}, %{match_participant_id: 1})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).score
    end

    test "requires both fields" do
      changeset = Score.changeset(%Score{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).match_participant_id
      assert "can't be blank" in errors_on(changeset).score
    end

    test "rejects negative score" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: -1
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).score
    end

    test "rejects large negative score" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: -100
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).score
    end

    test "treats nil match_participant_id as blank" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: nil,
          score: 21
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).match_participant_id
    end

    test "treats nil score as blank" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: nil
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).score
    end

    test "accepts score as string integer" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: "15"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :score) == 15
    end

    test "accepts match_participant_id as string integer" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: "2",
          score: 21
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :match_participant_id) == 2
    end

    test "rejects non-integer score" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: "not a number"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).score
    end

    test "rejects non-integer match_participant_id" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: "invalid",
          score: 21
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).match_participant_id
    end

    test "rejects float score" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: 21.5
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).score
    end

    test "rejects float match_participant_id" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1.5,
          score: 21
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).match_participant_id
    end

    test "does not cast unknown fields" do
      changeset =
        Score.changeset(%Score{}, %{
          match_participant_id: 1,
          score: 21,
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
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
