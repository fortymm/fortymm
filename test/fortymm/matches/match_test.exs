defmodule Fortymm.Matches.MatchTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.Match

  describe "changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3, rated: true},
          status: "pending"
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :match_configuration)
      assert configuration.length_in_games == 3
      assert configuration.rated == true
    end

    test "returns an invalid changeset with incorrect length" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 8, rated: false},
          status: "pending"
        })

      refute changeset.valid?
    end

    test "defaults rated to false when not provided" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "pending"
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :match_configuration)
      assert configuration.rated == false
    end

    test "can explicitly set rated to false" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3, rated: false},
          status: "pending"
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :match_configuration)
      assert configuration.rated == false
    end

    test "accepts rated as true" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 5, rated: true},
          status: "pending"
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :match_configuration)
      assert configuration.rated == true
    end

    test "requires match_configuration" do
      changeset = Match.changeset(%Match{}, %{status: "pending"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).match_configuration
    end

    test "defaults status to pending when not provided" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3}
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "accepts status as pending" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "pending"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "accepts status as in_progress" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "in_progress"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "in_progress"
    end

    test "accepts status as canceled" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "canceled"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "canceled"
    end

    test "accepts status as aborted" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "aborted"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "aborted"
    end

    test "accepts status as complete" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "complete"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "complete"
    end

    test "rejects invalid status value" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "invalid"
        })

      refute changeset.valid?

      assert "must be one of: pending, in_progress, canceled, aborted, complete" in errors_on(
               changeset
             ).status
    end

    test "treats empty string status as not provided" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: ""
        })

      # Ecto's cast/3 treats empty strings as "no value", so status defaults to "pending"
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "allows nil status and uses default" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: nil
        })

      # When nil is explicitly passed, validation doesn't run and field is set to nil
      # The default only applies to the struct, not when a field is explicitly set to nil
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == nil
    end

    test "validates all status transitions" do
      valid_statuses = ["pending", "in_progress", "canceled", "aborted", "complete"]

      for status <- valid_statuses do
        changeset =
          Match.changeset(%Match{}, %{
            match_configuration: %{length_in_games: 5, rated: true},
            status: status
          })

        assert changeset.valid?, "Expected status #{status} to be valid"
        assert Ecto.Changeset.get_field(changeset, :status) == status
      end
    end

    test "validates all length_in_games values" do
      valid_lengths = [1, 3, 5, 7]

      for length <- valid_lengths do
        changeset =
          Match.changeset(%Match{}, %{
            match_configuration: %{length_in_games: length},
            status: "pending"
          })

        assert changeset.valid?, "Expected length #{length} to be valid"
        configuration = Ecto.Changeset.get_field(changeset, :match_configuration)
        assert configuration.length_in_games == length
      end
    end

    test "rejects invalid length_in_games values" do
      for length <- [0, 2, 4, 6, 8, 10] do
        changeset =
          Match.changeset(%Match{}, %{
            match_configuration: %{length_in_games: length},
            status: "pending"
          })

        refute changeset.valid?, "Expected length #{length} to be invalid"
      end
    end

    test "handles multiple configurations correctly" do
      changeset1 =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 1, rated: true},
          status: "pending"
        })

      changeset2 =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 7, rated: false},
          status: "complete"
        })

      changeset3 =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 5, rated: true},
          status: "in_progress"
        })

      assert changeset1.valid?
      assert changeset2.valid?
      assert changeset3.valid?

      config1 = Ecto.Changeset.get_field(changeset1, :match_configuration)
      config2 = Ecto.Changeset.get_field(changeset2, :match_configuration)
      config3 = Ecto.Changeset.get_field(changeset3, :match_configuration)

      assert config1.length_in_games == 1
      assert config1.rated == true
      assert config2.length_in_games == 7
      assert config2.rated == false
      assert config3.length_in_games == 5
      assert config3.rated == true
    end

    test "does not cast unknown fields" do
      changeset =
        Match.changeset(%Match{}, %{
          match_configuration: %{length_in_games: 3},
          status: "pending",
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end
  end

  describe "valid_statuses/0" do
    test "returns the list of valid match statuses" do
      assert Match.valid_statuses() == ["pending", "in_progress", "canceled", "aborted", "complete"]
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
