defmodule Fortymm.Matches.ParticipantTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.Participant

  describe "changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 1,
          participant_number: 1
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :user_id) == 1
      assert Ecto.Changeset.get_field(changeset, :participant_number) == 1
    end

    test "accepts participant_number 1" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 42,
          participant_number: 1
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :participant_number) == 1
    end

    test "accepts participant_number 2" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 42,
          participant_number: 2
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :participant_number) == 2
    end

    test "requires user_id" do
      changeset =
        Participant.changeset(%Participant{}, %{
          participant_number: 1
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "requires participant_number" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 1
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).participant_number
    end

    test "rejects participant_number 0" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 1,
          participant_number: 0
        })

      refute changeset.valid?
      assert "must be 1 or 2" in errors_on(changeset).participant_number
    end

    test "rejects participant_number 3" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 1,
          participant_number: 3
        })

      refute changeset.valid?
      assert "must be 1 or 2" in errors_on(changeset).participant_number
    end

    test "rejects negative participant_number" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 1,
          participant_number: -1
        })

      refute changeset.valid?
      assert "must be 1 or 2" in errors_on(changeset).participant_number
    end

    test "accepts different user IDs" do
      changeset1 =
        Participant.changeset(%Participant{}, %{
          user_id: 100,
          participant_number: 1
        })

      changeset2 =
        Participant.changeset(%Participant{}, %{
          user_id: 999,
          participant_number: 2
        })

      assert changeset1.valid?
      assert changeset2.valid?
      assert Ecto.Changeset.get_field(changeset1, :user_id) == 100
      assert Ecto.Changeset.get_field(changeset2, :user_id) == 999
    end

    test "does not cast unknown fields" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 1,
          participant_number: 1,
          unknown_field: "value"
        })

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end

    test "treats nil user_id as blank" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: nil,
          participant_number: 1
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "treats nil participant_number as blank" do
      changeset =
        Participant.changeset(%Participant{}, %{
          user_id: 1,
          participant_number: nil
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).participant_number
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
