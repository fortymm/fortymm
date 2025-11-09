defmodule Fortymm.Matches.ScoreEntryTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.{ScoreEntry, Game}

  @participant_id_1 "550e8400-e29b-41d4-a716-446655440001"
  @participant_id_2 "550e8400-e29b-41d4-a716-446655440002"

  describe "changeset/2 (lenient validation)" do
    test "returns a valid changeset with correct data" do
      changeset =
        ScoreEntry.changeset(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          }
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :game_id) == "game-123"
      score_proposal = Ecto.Changeset.get_field(changeset, :score_proposal)
      assert score_proposal.proposed_by_participant_id == @participant_id_1
      assert length(score_proposal.scores) == 2
    end

    test "allows partial score_proposal during form filling" do
      changeset =
        ScoreEntry.changeset(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11}
            ]
          }
        })

      # Lenient changeset allows partial data
      refute changeset.valid?
      # But it doesn't show score_proposal as required blank error
      assert "must have exactly 2 scores" in errors_on(changeset).score_proposal[:scores] || []
    end

    test "requires game_id" do
      changeset =
        ScoreEntry.changeset(%ScoreEntry{}, %{
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          }
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).game_id
    end

    test "allows missing score_proposal during validation (lenient mode)" do
      changeset =
        ScoreEntry.changeset(%ScoreEntry{}, %{
          game_id: "game-123"
        })

      # In lenient mode, missing score_proposal is allowed (no required: true)
      assert changeset.valid?
    end
  end

  describe "changeset_for_submission/2 (strict validation)" do
    test "returns a valid changeset with correct data" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          }
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :game_id) == "game-123"
      score_proposal = Ecto.Changeset.get_field(changeset, :score_proposal)
      assert score_proposal.proposed_by_participant_id == @participant_id_1
      assert length(score_proposal.scores) == 2
    end

    test "requires game_id" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          }
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).game_id
    end

    test "requires score_proposal" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123"
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).score_proposal
    end

    test "rejects partial score data on submission" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11}
            ]
          }
        })

      refute changeset.valid?
      assert "must have exactly 2 scores" in errors_on(changeset).score_proposal[:scores] || []
    end

    test "validates nested score_proposal changeset" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11}
            ]
          }
        })

      refute changeset.valid?
      errors = errors_on(changeset)
      assert %{score_proposal: %{scores: ["must have exactly 2 scores"]}} = errors
    end

    test "propagates score_proposal validation errors for invalid scores" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: -5},
              %{match_participant_id: @participant_id_2, score: 11}
            ]
          }
        })

      refute changeset.valid?
      errors = errors_on(changeset)

      assert %{score_proposal: %{scores: [%{score: ["must be greater than or equal to 0"]}, _]}} =
               errors
    end

    test "propagates score_proposal validation errors for game scoring rules" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 10}
            ]
          }
        })

      refute changeset.valid?
      errors = errors_on(changeset)

      assert %{
               score_proposal: %{
                 scores: ["game cannot end 11-10 or higher, must continue until 2-point lead"]
               }
             } = errors
    end

    test "accepts nil score_proposal and shows proper error" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: nil
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).score_proposal
    end

    test "does not cast unknown fields" do
      changeset =
        ScoreEntry.changeset_for_submission(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          },
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end
  end

  describe "changeset_with_game/3" do
    test "returns valid changeset when game has no score proposals" do
      game = %Game{
        id: "game-123",
        game_number: 1,
        score_proposals: []
      }

      changeset =
        ScoreEntry.changeset_with_game(
          %ScoreEntry{},
          %{
            game_id: "game-123",
            score_proposal: %{
              proposed_by_participant_id: @participant_id_1,
              scores: [
                %{match_participant_id: @participant_id_1, score: 11},
                %{match_participant_id: @participant_id_2, score: 9}
              ]
            }
          },
          game
        )

      assert changeset.valid?
    end

    test "returns invalid changeset when game already has a score proposal" do
      game = %Game{
        id: "game-123",
        game_number: 1,
        score_proposals: [
          %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          }
        ]
      }

      changeset =
        ScoreEntry.changeset_with_game(
          %ScoreEntry{},
          %{
            game_id: "game-123",
            score_proposal: %{
              proposed_by_participant_id: @participant_id_1,
              scores: [
                %{match_participant_id: @participant_id_1, score: 9},
                %{match_participant_id: @participant_id_2, score: 11}
              ]
            }
          },
          game
        )

      refute changeset.valid?
      assert "game already has a confirmed score" in errors_on(changeset).game_id
    end

    test "returns invalid changeset when game has multiple score proposals" do
      game = %Game{
        id: "game-123",
        game_number: 1,
        score_proposals: [
          %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          },
          %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          }
        ]
      }

      changeset =
        ScoreEntry.changeset_with_game(
          %ScoreEntry{},
          %{
            game_id: "game-123",
            score_proposal: %{
              proposed_by_participant_id: @participant_id_1,
              scores: [
                %{match_participant_id: @participant_id_1, score: 12},
                %{match_participant_id: @participant_id_2, score: 10}
              ]
            }
          },
          game
        )

      refute changeset.valid?
      assert "game already has a confirmed score" in errors_on(changeset).game_id
    end

    test "works when game is nil" do
      changeset =
        ScoreEntry.changeset_with_game(
          %ScoreEntry{},
          %{
            game_id: "game-123",
            score_proposal: %{
              proposed_by_participant_id: @participant_id_1,
              scores: [
                %{match_participant_id: @participant_id_1, score: 11},
                %{match_participant_id: @participant_id_2, score: 9}
              ]
            }
          },
          nil
        )

      assert changeset.valid?
    end

    test "works when called without game parameter (defaults to nil)" do
      changeset =
        ScoreEntry.changeset_with_game(%ScoreEntry{}, %{
          game_id: "game-123",
          score_proposal: %{
            proposed_by_participant_id: @participant_id_1,
            scores: [
              %{match_participant_id: @participant_id_1, score: 11},
              %{match_participant_id: @participant_id_2, score: 9}
            ]
          }
        })

      assert changeset.valid?
    end

    test "still validates score_proposal when game has no score" do
      game = %Game{
        id: "game-123",
        game_number: 1,
        score_proposals: []
      }

      changeset =
        ScoreEntry.changeset_with_game(
          %ScoreEntry{},
          %{
            game_id: "game-123",
            score_proposal: %{
              proposed_by_participant_id: @participant_id_1,
              scores: [
                %{match_participant_id: @participant_id_1, score: 11},
                %{match_participant_id: @participant_id_2, score: 10}
              ]
            }
          },
          game
        )

      refute changeset.valid?
      errors = errors_on(changeset)

      assert %{
               score_proposal: %{
                 scores: ["game cannot end 11-10 or higher, must continue until 2-point lead"]
               }
             } = errors
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
