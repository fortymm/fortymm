defmodule Fortymm.Matches.GameTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.Game

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
