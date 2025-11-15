defmodule Fortymm.Matches.ConfigurationTest do
  use ExUnit.Case, async: false

  alias Fortymm.Matches.Configuration

  describe "changeset/2" do
    test "validates valid length_in_games values" do
      for length <- [1, 3, 5, 7] do
        changeset = Configuration.changeset(%Configuration{}, %{length_in_games: length})
        assert changeset.valid?, "Expected length #{length} to be valid"
      end
    end

    test "rejects invalid length_in_games values" do
      for length <- [0, 2, 4, 6, 8, 10, -1, 100] do
        changeset = Configuration.changeset(%Configuration{}, %{length_in_games: length})
        refute changeset.valid?, "Expected length #{length} to be invalid"
        assert "must be one of: 1, 3, 5, 7" in errors_on(changeset).length_in_games
      end
    end

    test "requires length_in_games" do
      changeset = Configuration.changeset(%Configuration{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).length_in_games
    end

    test "accepts rated as true" do
      changeset =
        Configuration.changeset(%Configuration{}, %{length_in_games: 3, rated: true})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == true
    end

    test "accepts rated as false" do
      changeset =
        Configuration.changeset(%Configuration{}, %{length_in_games: 3, rated: false})

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == false
    end

    test "defaults rated to false when not provided" do
      changeset = Configuration.changeset(%Configuration{}, %{length_in_games: 5})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == false
    end

    test "accepts string values for length_in_games" do
      changeset = Configuration.changeset(%Configuration{}, %{"length_in_games" => "3"})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :length_in_games) == 3
    end

    test "accepts string values for rated" do
      changeset =
        Configuration.changeset(%Configuration{}, %{
          "length_in_games" => "5",
          "rated" => "true"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :rated) == true
    end

    test "rejects nil for length_in_games" do
      changeset = Configuration.changeset(%Configuration{}, %{length_in_games: nil})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).length_in_games
    end

    test "accepts nil for rated (keeps nil when explicitly provided)" do
      changeset =
        Configuration.changeset(%Configuration{}, %{length_in_games: 3, rated: nil})

      assert changeset.valid?
      # When rated is explicitly set to nil, it gets cast as nil
      assert Ecto.Changeset.get_change(changeset, :rated) == nil
      # When we apply changes, nil is set (overriding the default)
      assert Ecto.Changeset.get_field(changeset, :rated) == nil
    end

    test "handles invalid data types for length_in_games" do
      changeset =
        Configuration.changeset(%Configuration{}, %{length_in_games: "invalid"})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).length_in_games
    end

    test "handles multiple validation errors" do
      changeset = Configuration.changeset(%Configuration{}, %{})
      refute changeset.valid?
      assert Map.has_key?(errors_on(changeset), :length_in_games)
    end

    test "does not cast unknown fields" do
      changeset =
        Configuration.changeset(%Configuration{}, %{
          length_in_games: 3,
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end
  end

  describe "valid_lengths/0" do
    test "returns the list of valid game lengths" do
      assert Configuration.valid_lengths() == [1, 3, 5, 7]
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
