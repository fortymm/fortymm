defmodule Fortymm.Matches.ChallengeCancellationTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.{Challenge, ChallengeCancellation, Configuration}

  describe "changeset/2" do
    test "valid with pending challenge and same cancellor as creator" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 1
        })

      assert changeset.valid?
    end

    test "invalid when cancellor_id is missing" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).cancellor_id
    end

    test "invalid when cancellor_id is nil" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: nil
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).cancellor_id
    end

    test "invalid when challenge is missing" do
      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          cancellor_id: 1
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).challenge
    end

    test "invalid when challenge is nil" do
      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: nil,
          cancellor_id: 1
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).challenge
    end

    test "invalid when cancellor is different from creator" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 2
        })

      refute changeset.valid?
      assert "can only cancel your own challenge" in errors_on(changeset).cancellor_id
    end

    test "invalid when challenge status is accepted" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "accepted",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 1
        })

      refute changeset.valid?
      assert "must be pending, but is accepted" in errors_on(changeset).challenge
    end

    test "invalid when challenge status is rejected" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "rejected",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 1
        })

      refute changeset.valid?
      assert "must be pending, but is rejected" in errors_on(changeset).challenge
    end

    test "invalid when challenge status is cancelled" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "cancelled",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 1
        })

      refute changeset.valid?
      assert "must be pending, but is cancelled" in errors_on(changeset).challenge
    end

    test "valid with same user ID for creator and cancellor" do
      challenge = %Challenge{
        id: "xyz789",
        created_by_id: 999,
        status: "pending",
        configuration: %Configuration{length_in_games: 5, rated: true}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 999
        })

      assert changeset.valid?
    end

    test "valid with rated challenge" do
      challenge = %Challenge{
        id: "rated123",
        created_by_id: 5,
        status: "pending",
        configuration: %Configuration{length_in_games: 7, rated: true}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 5
        })

      assert changeset.valid?
    end

    test "valid with unrated challenge" do
      challenge = %Challenge{
        id: "unrated456",
        created_by_id: 15,
        status: "pending",
        configuration: %Configuration{length_in_games: 1, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 15
        })

      assert changeset.valid?
    end

    test "invalid with both cancellor different from creator and non-pending status" do
      challenge = %Challenge{
        id: "abc123",
        created_by_id: 1,
        status: "accepted",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 2
        })

      refute changeset.valid?
      errors = errors_on(changeset)
      # Should have both errors
      assert "can only cancel your own challenge" in errors.cancellor_id
      assert "must be pending, but is accepted" in errors.challenge
    end

    test "valid changeset contains embedded challenge" do
      challenge = %Challenge{
        id: "embed123",
        created_by_id: 42,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: true}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 42
        })

      assert changeset.valid?
      embedded_challenge = Ecto.Changeset.get_field(changeset, :challenge)
      assert embedded_challenge.id == "embed123"
      assert embedded_challenge.created_by_id == 42
      assert embedded_challenge.status == "pending"
      assert embedded_challenge.configuration.length_in_games == 3
      assert embedded_challenge.configuration.rated == true
    end

    test "changeset stores cancellor_id correctly" do
      challenge = %Challenge{
        id: "store123",
        created_by_id: 100,
        status: "pending",
        configuration: %Configuration{length_in_games: 5, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 100
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :cancellor_id) == 100
    end

    test "handles string cancellor_id by casting to integer" do
      challenge = %Challenge{
        id: "string123",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: "1"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :cancellor_id) == 1
    end

    test "invalid with invalid cancellor_id data type" do
      challenge = %Challenge{
        id: "invalid123",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: "not_a_number"
        })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).cancellor_id
    end

    test "does not cast unknown fields" do
      challenge = %Challenge{
        id: "unknown123",
        created_by_id: 1,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 1,
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end

    test "validates cancellor can be zero matching creator id zero" do
      challenge = %Challenge{
        id: "zero123",
        created_by_id: 0,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 0
        })

      assert changeset.valid?
    end

    test "invalid when cancellor id is different even with same digits" do
      challenge = %Challenge{
        id: "digits123",
        created_by_id: 123,
        status: "pending",
        configuration: %Configuration{length_in_games: 3, rated: false}
      }

      changeset =
        ChallengeCancellation.changeset(%ChallengeCancellation{}, %{
          challenge: challenge,
          cancellor_id: 321
        })

      refute changeset.valid?
      assert "can only cancel your own challenge" in errors_on(changeset).cancellor_id
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
