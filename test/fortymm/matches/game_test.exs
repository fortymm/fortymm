defmodule Fortymm.Matches.GameTest do
  use ExUnit.Case, async: false

  alias Fortymm.Matches.Game

  @participant_id_1 "550e8400-e29b-41d4-a716-446655440001"
  @participant_id_2 "550e8400-e29b-41d4-a716-446655440002"
  @proposer_id "550e8400-e29b-41d4-a716-446655440003"

  describe "changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :game_number) == 1
    end

    test "accepts game_number 1" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :game_number) == 1
    end

    test "accepts game_number 2" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 2
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :game_number) == 2
    end

    test "accepts game_number greater than minimum valid value" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 100
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :game_number) == 100
    end

    test "requires game_number" do
      changeset = Game.changeset(%Game{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).game_number
    end

    test "rejects game_number 0" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 0
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).game_number
    end

    test "rejects negative game_number" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: -1
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).game_number
    end

    test "rejects large negative game_number" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: -100
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).game_number
    end

    test "does not cast unknown fields" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end

    test "treats nil game_number as blank" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: nil
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).game_number
    end

    test "accepts game_number as string integer" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: "5"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :game_number) == 5
    end

    test "rejects non-integer game_number" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: "not a number"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).game_number
    end

    test "rejects float game_number" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1.5
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).game_number
    end

    test "accepts embedded score_proposals" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          score_proposals: [
            %{
              proposed_by_participant_id: @proposer_id,
              scores: [
                %{match_participant_id: @participant_id_1, score: 11},
                %{match_participant_id: @participant_id_2, score: 9}
              ]
            }
          ]
        })

      assert changeset.valid?
      score_proposals = Ecto.Changeset.get_field(changeset, :score_proposals)
      assert length(score_proposals) == 1
    end

    test "accepts multiple score_proposals" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          score_proposals: [
            %{
              proposed_by_participant_id: @proposer_id,
              scores: [
                %{match_participant_id: @participant_id_1, score: 11},
                %{match_participant_id: @participant_id_2, score: 8}
              ]
            },
            %{
              proposed_by_participant_id: @proposer_id,
              scores: [
                %{match_participant_id: @participant_id_1, score: 9},
                %{match_participant_id: @participant_id_2, score: 11}
              ]
            }
          ]
        })

      assert changeset.valid?
      score_proposals = Ecto.Changeset.get_field(changeset, :score_proposals)
      assert length(score_proposals) == 2
    end

    test "accepts empty score_proposals" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          score_proposals: []
        })

      assert changeset.valid?
    end

    test "validates nested score_proposal changesets" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          score_proposals: [
            %{
              proposed_by_participant_id: @proposer_id,
              scores: [
                %{match_participant_id: @participant_id_1, score: -5},
                %{match_participant_id: @participant_id_2, score: 21}
              ]
            }
          ]
        })

      refute changeset.valid?
      errors = errors_on(changeset)

      assert %{
               score_proposals: [%{scores: [%{score: ["must be greater than or equal to 0"]}, _]}]
             } = errors
    end

    test "rejects score_proposal with single score" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          score_proposals: [
            %{
              proposed_by_participant_id: @proposer_id,
              scores: [
                %{match_participant_id: @participant_id_1, score: 21}
              ]
            }
          ]
        })

      refute changeset.valid?
      errors = errors_on(changeset)
      assert %{score_proposals: [%{scores: ["must have exactly 2 scores"]}]} = errors
    end

    test "rejects score_proposal with more than 2 scores" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          score_proposals: [
            %{
              proposed_by_participant_id: @proposer_id,
              scores: [
                %{match_participant_id: @participant_id_1, score: 21},
                %{match_participant_id: @participant_id_2, score: 19},
                %{match_participant_id: @participant_id_1, score: 15}
              ]
            }
          ]
        })

      refute changeset.valid?
      errors = errors_on(changeset)
      assert %{score_proposals: [%{scores: ["must have exactly 2 scores"]}]} = errors
    end

    test "validates all nested score_proposal data" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1,
          score_proposals: [
            %{
              scores: [
                %{match_participant_id: @participant_id_1, score: 21},
                %{match_participant_id: @participant_id_2, score: 19}
              ]
            }
          ]
        })

      refute changeset.valid?
      errors = errors_on(changeset)
      assert %{score_proposals: [%{proposed_by_participant_id: ["can't be blank"]}]} = errors
    end

    test "can have game with valid data and no score_proposals" do
      changeset =
        Game.changeset(%Game{}, %{
          game_number: 1
        })

      assert changeset.valid?
      score_proposals = Ecto.Changeset.get_field(changeset, :score_proposals)
      assert score_proposals == []
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
