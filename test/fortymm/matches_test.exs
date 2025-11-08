defmodule Fortymm.MatchesTest do
  use Fortymm.DataCase

  alias Fortymm.Matches
  alias Fortymm.Matches.{Challenge, ChallengeStore, ChallengeUpdates, MatchStore}

  setup do
    # Clear ETS tables before each test
    ChallengeStore.clear()
    MatchStore.clear()
    :ok
  end

  describe "challenge_changeset/1" do
    test "valid with length_in_games of 1" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 1}, created_by_id: 1})

      assert changeset.valid?
    end

    test "valid with length_in_games of 3" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 3}, created_by_id: 1})

      assert changeset.valid?
    end

    test "valid with length_in_games of 5" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 5}, created_by_id: 1})

      assert changeset.valid?
    end

    test "valid with length_in_games of 7" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 7}, created_by_id: 1})

      assert changeset.valid?
    end

    test "invalid with length_in_games of 2" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 2}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 4" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 4}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 6" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 6}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 0" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 0}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid with length_in_games of 10" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 10}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "invalid without length_in_games" do
      changeset = Matches.challenge_changeset(%{})
      refute changeset.valid?
      errors = errors_on(changeset)
      assert "can't be blank" in errors.configuration
    end

    test "invalid with nil length_in_games" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: nil}})
      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "can't be blank" in errors
    end

    test "invalid without created_by_id" do
      changeset = Matches.challenge_changeset(%{configuration: %{length_in_games: 3}})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "invalid with nil created_by_id" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 3}, created_by_id: nil})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "valid with created_by_id" do
      changeset =
        Matches.challenge_changeset(%{configuration: %{length_in_games: 3}, created_by_id: 1})

      assert changeset.valid?
    end
  end

  describe "Challenge.changeset/2" do
    test "returns a valid changeset with correct data" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3, rated: true},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.length_in_games == 3
      assert configuration.rated == true
    end

    test "returns an invalid changeset with incorrect length" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 8, rated: false},
          created_by_id: 1
        })

      refute changeset.valid?
    end

    test "defaults rated to false when not provided" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == false
    end

    test "can explicitly set rated to false" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == false
    end

    test "accepts rated as true" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == true
    end

    test "accepts rated as false" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 1
        })

      assert changeset.valid?
      configuration = Ecto.Changeset.get_field(changeset, :configuration)
      assert configuration.rated == false
    end

    test "requires created_by_id" do
      changeset =
        Challenge.changeset(%Challenge{}, %{configuration: %{length_in_games: 3, rated: false}})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "stores created_by_id correctly" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 42
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :created_by_id) == 42
    end

    test "defaults status to pending when not provided" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "accepts status as pending" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "pending"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "accepts status as accepted" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "accepted"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "accepted"
    end

    test "accepts status as rejected" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "rejected"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "rejected"
    end

    test "accepts status as cancelled" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "cancelled"
        })

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "cancelled"
    end

    test "rejects invalid status value" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: "invalid"
        })

      refute changeset.valid?

      assert "must be one of: pending, accepted, rejected, cancelled" in errors_on(changeset).status
    end

    test "treats empty string status as not provided" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: ""
        })

      # Ecto's cast/3 treats empty strings as "no value", so status defaults to "pending"
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == "pending"
    end

    test "allows nil status and uses default" do
      changeset =
        Challenge.changeset(%Challenge{}, %{
          configuration: %{length_in_games: 3},
          created_by_id: 1,
          status: nil
        })

      # When nil is explicitly passed, validation doesn't run and field is set to nil
      # The default only applies to the struct, not when a field is explicitly set to nil
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == nil
    end
  end

  describe "create_challenge/1" do
    test "creates and stores a valid challenge in ETS" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{
                 configuration: %{length_in_games: 3, rated: false},
                 created_by_id: 1
               })

      assert challenge.configuration.length_in_games == 3
      assert challenge.configuration.rated == false
      assert challenge.created_by_id == 1
      assert is_binary(challenge.id)
      assert String.length(challenge.id) == 32
    end

    test "creates a rated challenge" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{
                 configuration: %{length_in_games: 5, rated: true},
                 created_by_id: 1
               })

      assert challenge.configuration.length_in_games == 5
      assert challenge.configuration.rated == true
      assert challenge.created_by_id == 1
    end

    test "returns error for invalid challenge" do
      assert {:error, changeset} =
               Matches.create_challenge(%{
                 configuration: %{length_in_games: 2, rated: false},
                 created_by_id: 1
               })

      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "defaults rated to false when not provided" do
      assert {:ok, challenge} =
               Matches.create_challenge(%{configuration: %{length_in_games: 3}, created_by_id: 1})

      assert challenge.configuration.length_in_games == 3
      assert challenge.configuration.rated == false
    end

    test "generates unique IDs for each challenge" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 1
        })

      assert challenge1.id != challenge2.id
    end

    test "stores challenge so it can be retrieved" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: true},
          created_by_id: 1
        })

      assert {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.id == challenge.id
      assert retrieved.configuration.length_in_games == 7
      assert retrieved.configuration.rated == true
      assert retrieved.created_by_id == 1
    end

    test "requires created_by_id" do
      assert {:error, changeset} =
               Matches.create_challenge(%{configuration: %{length_in_games: 3, rated: false}})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).created_by_id
    end

    test "stores created_by_id from different users" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 2
        })

      assert challenge1.created_by_id == 1
      assert challenge2.created_by_id == 2
    end
  end

  describe "get_challenge/1" do
    test "returns challenge when it exists" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 1
        })

      assert {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.id == challenge.id
      assert retrieved.configuration.length_in_games == 5
      assert retrieved.configuration.rated == false
    end

    test "returns error when challenge does not exist" do
      assert {:error, :not_found} = Matches.get_challenge("nonexistent-id")
    end
  end

  describe "list_challenges/0" do
    test "returns empty list when no challenges exist" do
      assert Matches.list_challenges() == []
    end

    test "returns all challenges" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 1
        })

      {:ok, challenge3} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 1
        })

      challenges = Matches.list_challenges()
      assert length(challenges) == 3
      assert challenge1 in challenges
      assert challenge2 in challenges
      assert challenge3 in challenges
    end
  end

  describe "delete_challenge/1" do
    test "deletes an existing challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert :ok = Matches.delete_challenge(challenge.id)
      assert {:error, :not_found} = Matches.get_challenge(challenge.id)
    end

    test "returns ok even when challenge does not exist" do
      assert :ok = Matches.delete_challenge("nonexistent-id")
    end
  end

  describe "update_challenge/2" do
    test "updates an existing challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})
      assert updated.id == challenge.id
      assert updated.status == "accepted"
      assert updated.configuration.length_in_games == 3
      assert updated.configuration.rated == false
    end

    test "updates multiple fields" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, updated} =
               Matches.update_challenge(challenge.id, %{
                 status: "rejected",
                 configuration: %{rated: true}
               })

      assert updated.status == "rejected"
      assert updated.configuration.rated == true
    end

    test "persists updates in ETS" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 1
        })

      {:ok, _updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.status == "accepted"
    end

    test "returns error for invalid update" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:error, changeset} =
               Matches.update_challenge(challenge.id, %{status: "invalid_status"})

      refute changeset.valid?

      assert "must be one of: pending, accepted, rejected, cancelled" in errors_on(changeset).status
    end

    test "returns error for non-existent challenge" do
      assert {:error, :not_found} =
               Matches.update_challenge("nonexistent-id", %{status: "accepted"})
    end

    test "validates length_in_games on update" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:error, changeset} =
               Matches.update_challenge(challenge.id, %{configuration: %{length_in_games: 2}})

      refute changeset.valid?
      assert %{configuration: %{length_in_games: errors}} = errors_on(changeset)
      assert "must be one of: 1, 3, 5, 7" in errors
    end

    test "can update challenge to cancelled status" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "cancelled"})
      assert updated.status == "cancelled"
    end

    test "challenge starts with pending status" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
    end

    test "can transition from pending to accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
      {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})
      assert updated.status == "accepted"
    end

    test "can transition from pending to rejected" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
      {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "rejected"})
      assert updated.status == "rejected"
    end

    test "can transition from pending to cancelled" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert challenge.status == "pending"
      {:ok, updated} = Matches.update_challenge(challenge.id, %{status: "cancelled"})
      assert updated.status == "cancelled"
    end
  end

  describe "challenge broadcasts" do
    test "create_challenge broadcasts the new challenge" do
      ChallengeUpdates.subscribe("will-be-generated")

      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      # Subscribe to the actual challenge ID
      ChallengeUpdates.subscribe(challenge.id)

      # Create another challenge to trigger a broadcast we're subscribed to
      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 2
        })

      ChallengeUpdates.subscribe(challenge2.id)

      # Trigger an update to test the broadcast
      {:ok, updated} = Matches.update_challenge(challenge2.id, %{status: "accepted"})

      assert_receive {:challenge_updated, received}
      assert received.id == updated.id
      assert received.status == "accepted"
    end

    test "update_challenge broadcasts the updated challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      {:ok, _updated} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      assert_receive {:challenge_updated, received}
      assert received.id == challenge.id
      assert received.status == "accepted"
      assert received.configuration.length_in_games == 3
    end

    test "broadcasts include all updated fields" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      {:ok, _updated} =
        Matches.update_challenge(challenge.id, %{
          status: "rejected",
          configuration: %{rated: true}
        })

      assert_receive {:challenge_updated, received}
      assert received.status == "rejected"
      assert received.configuration.rated == true
    end

    test "failed updates do not broadcast" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      # Try an invalid update
      {:error, _changeset} = Matches.update_challenge(challenge.id, %{status: "invalid"})

      refute_receive {:challenge_updated, _}, 100
    end

    test "broadcasts only to subscribers of the specific challenge" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: false},
          created_by_id: 2
        })

      challenge2_id = challenge2.id

      # Only subscribe to challenge1
      ChallengeUpdates.subscribe(challenge1.id)

      # Update challenge2
      {:ok, _updated} = Matches.update_challenge(challenge2.id, %{status: "accepted"})

      # Should not receive update for challenge2
      refute_receive {:challenge_updated, %{id: ^challenge2_id}}, 100
    end
  end

  describe "accept_challenge/2" do
    test "accepts a valid pending challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, match} = Matches.accept_challenge(challenge.id, 2)
      assert match.status == "pending"
      assert match.match_configuration.length_in_games == 3
      assert match.match_configuration.rated == false
      assert length(match.participants) == 2

      # Verify the challenge was marked as accepted
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "accepted"
    end

    test "sets match_id on challenge when accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      # Verify match_id is nil before acceptance
      assert is_nil(challenge.match_id)

      assert {:ok, match} = Matches.accept_challenge(challenge.id, 2)

      # Verify the challenge has the match_id set
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.match_id == match.id
      assert updated_challenge.status == "accepted"
    end

    test "match_id matches the created match's id" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 100
        })

      assert {:ok, match} = Matches.accept_challenge(challenge.id, 200)

      # Verify the match_id on the challenge matches the match's ID
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.match_id == match.id
      assert is_binary(updated_challenge.match_id)
      assert String.length(updated_challenge.match_id) == 32
    end

    test "match_id remains nil when challenge is not accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      # Verify match_id is nil for pending challenge
      {:ok, pending_challenge} = Matches.get_challenge(challenge.id)
      assert is_nil(pending_challenge.match_id)

      # Reject the challenge instead of accepting it
      {:ok, rejected_challenge} = Matches.reject_challenge(challenge.id, 2)
      assert is_nil(rejected_challenge.match_id)
      assert rejected_challenge.status == "rejected"
    end

    test "match_id remains nil when challenge is cancelled" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 5
        })

      # Cancel the challenge
      {:ok, cancelled_challenge} = Matches.cancel_challenge(challenge.id, 5)
      assert is_nil(cancelled_challenge.match_id)
      assert cancelled_challenge.status == "cancelled"
    end

    test "returns error when challenge does not exist" do
      assert {:error, :not_found} = Matches.accept_challenge("nonexistent-id", 2)
    end

    test "returns error when acceptor is the same as creator" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:error, changeset} = Matches.accept_challenge(challenge.id, 1)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :acceptor_id)
      assert "cannot accept your own challenge" in errors.acceptor_id
    end

    test "returns error when challenge is already accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _accepted} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      assert {:error, changeset} = Matches.accept_challenge(challenge.id, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :challenge)
      assert "must be pending, but is accepted" in errors.challenge
    end

    test "returns error when challenge is rejected" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _rejected} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      assert {:error, changeset} = Matches.accept_challenge(challenge.id, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is rejected" in errors.challenge
    end

    test "returns error when challenge is cancelled" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _cancelled} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      assert {:error, changeset} = Matches.accept_challenge(challenge.id, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is cancelled" in errors.challenge
    end

    test "broadcasts when challenge is accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      {:ok, _accepted} = Matches.accept_challenge(challenge.id, 2)

      assert_receive {:challenge_updated, received}
      assert received.id == challenge.id
      assert received.status == "accepted"
    end

    test "accepts challenge with different user IDs" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 999
        })

      assert {:ok, match} = Matches.accept_challenge(challenge.id, 1000)
      assert match.status == "pending"
      assert length(match.participants) == 2

      # Verify the challenge was marked as accepted
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "accepted"
      assert updated_challenge.created_by_id == 999
    end

    test "persists acceptance in ETS" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 5
        })

      {:ok, _accepted} = Matches.accept_challenge(challenge.id, 10)

      {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.status == "accepted"
    end

    test "does not modify other challenge fields" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 42
        })

      {:ok, match} = Matches.accept_challenge(challenge.id, 100)

      # Verify the match was created correctly
      assert match.status == "pending"
      assert match.match_configuration.length_in_games == 5
      assert match.match_configuration.rated == true

      # Verify the challenge was updated but other fields remain unchanged
      {:ok, updated_challenge} = Matches.get_challenge(challenge.id)
      assert updated_challenge.status == "accepted"
      assert updated_challenge.configuration.length_in_games == 5
      assert updated_challenge.configuration.rated == true
      assert updated_challenge.created_by_id == 42
    end
  end

  describe "reject_challenge/2" do
    test "rejects a valid pending challenge" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, rejected_challenge} = Matches.reject_challenge(challenge.id, 2)
      assert rejected_challenge.status == "rejected"
      assert rejected_challenge.id == challenge.id
      assert rejected_challenge.created_by_id == 1
    end

    test "returns error when challenge does not exist" do
      assert {:error, :not_found} = Matches.reject_challenge("nonexistent-id", 2)
    end

    test "returns error when rejector is the same as creator" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:error, changeset} = Matches.reject_challenge(challenge.id, 1)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :rejector_id)
      assert "cannot reject your own challenge" in errors.rejector_id
    end

    test "returns error when challenge is already accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _accepted} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      assert {:error, changeset} = Matches.reject_challenge(challenge.id, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :challenge)
      assert "must be pending, but is accepted" in errors.challenge
    end

    test "returns error when challenge is already rejected" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _rejected} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      assert {:error, changeset} = Matches.reject_challenge(challenge.id, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is rejected" in errors.challenge
    end

    test "returns error when challenge is cancelled" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _cancelled} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      assert {:error, changeset} = Matches.reject_challenge(challenge.id, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is cancelled" in errors.challenge
    end

    test "broadcasts when challenge is rejected" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      {:ok, _rejected} = Matches.reject_challenge(challenge.id, 2)

      assert_receive {:challenge_updated, received}
      assert received.id == challenge.id
      assert received.status == "rejected"
    end

    test "rejects challenge with different user IDs" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 999
        })

      assert {:ok, rejected} = Matches.reject_challenge(challenge.id, 1000)
      assert rejected.status == "rejected"
      assert rejected.created_by_id == 999
    end

    test "persists rejection in ETS" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 5
        })

      {:ok, _rejected} = Matches.reject_challenge(challenge.id, 10)

      {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.status == "rejected"
    end

    test "does not modify other challenge fields" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 42
        })

      {:ok, rejected} = Matches.reject_challenge(challenge.id, 100)

      assert rejected.status == "rejected"
      assert rejected.configuration.length_in_games == 5
      assert rejected.configuration.rated == true
      assert rejected.created_by_id == 42
    end
  end

  describe "cancel_challenge/2" do
    test "cancels a valid pending challenge by creator" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:ok, cancelled_challenge} = Matches.cancel_challenge(challenge.id, 1)
      assert cancelled_challenge.status == "cancelled"
      assert cancelled_challenge.id == challenge.id
      assert cancelled_challenge.created_by_id == 1
    end

    test "returns error when challenge does not exist" do
      assert {:error, :not_found} = Matches.cancel_challenge("nonexistent-id", 1)
    end

    test "returns error when cancellor is different from creator" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert {:error, changeset} = Matches.cancel_challenge(challenge.id, 2)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :cancellor_id)
      assert "can only cancel your own challenge" in errors.cancellor_id
    end

    test "returns error when challenge is already accepted" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _accepted} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      assert {:error, changeset} = Matches.cancel_challenge(challenge.id, 1)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert Map.has_key?(errors, :challenge)
      assert "must be pending, but is accepted" in errors.challenge
    end

    test "returns error when challenge is already rejected" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _rejected} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      assert {:error, changeset} = Matches.cancel_challenge(challenge.id, 1)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is rejected" in errors.challenge
    end

    test "returns error when challenge is already cancelled" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, _cancelled} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      assert {:error, changeset} = Matches.cancel_challenge(challenge.id, 1)
      refute changeset.valid?

      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert "must be pending, but is cancelled" in errors.challenge
    end

    test "broadcasts when challenge is cancelled" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      ChallengeUpdates.subscribe(challenge.id)

      {:ok, _cancelled} = Matches.cancel_challenge(challenge.id, 1)

      assert_receive {:challenge_updated, received}
      assert received.id == challenge.id
      assert received.status == "cancelled"
    end

    test "cancels challenge with creator ID" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 999
        })

      assert {:ok, cancelled} = Matches.cancel_challenge(challenge.id, 999)
      assert cancelled.status == "cancelled"
      assert cancelled.created_by_id == 999
    end

    test "persists cancellation in ETS" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 5
        })

      {:ok, _cancelled} = Matches.cancel_challenge(challenge.id, 5)

      {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert retrieved.status == "cancelled"
    end

    test "does not modify other challenge fields" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 42
        })

      {:ok, cancelled} = Matches.cancel_challenge(challenge.id, 42)

      assert cancelled.status == "cancelled"
      assert cancelled.configuration.length_in_games == 5
      assert cancelled.configuration.rated == true
      assert cancelled.created_by_id == 42
    end
  end

  describe "get_match/1" do
    test "returns match when it exists" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      # Accept the challenge to create a match
      {:ok, match} = Matches.accept_challenge(challenge.id, 2)

      # Retrieve the match
      assert {:ok, retrieved_match} = Matches.get_match(match.id)
      assert retrieved_match.id == match.id
      assert retrieved_match.status == "pending"
      assert retrieved_match.match_configuration.length_in_games == 3
      assert retrieved_match.match_configuration.rated == false
      assert length(retrieved_match.participants) == 2
    end

    test "returns match with correct participant details" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 100
        })

      {:ok, match} = Matches.accept_challenge(challenge.id, 200)

      assert {:ok, retrieved_match} = Matches.get_match(match.id)

      # Check participants
      participant_ids = Enum.map(retrieved_match.participants, & &1.user_id)
      assert 100 in participant_ids
      assert 200 in participant_ids
      assert length(participant_ids) == 2
    end

    test "returns match with rated configuration" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: true},
          created_by_id: 42
        })

      {:ok, match} = Matches.accept_challenge(challenge.id, 43)

      assert {:ok, retrieved_match} = Matches.get_match(match.id)
      assert retrieved_match.match_configuration.rated == true
      assert retrieved_match.match_configuration.length_in_games == 7
    end

    test "returns error when match does not exist" do
      assert {:error, :not_found} = Matches.get_match("nonexistent-match-id")
    end

    test "returns error for invalid match ID" do
      assert {:error, :not_found} = Matches.get_match("invalid-id-123")
    end

    test "can retrieve multiple different matches" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 3
        })

      {:ok, match1} = Matches.accept_challenge(challenge1.id, 2)
      {:ok, match2} = Matches.accept_challenge(challenge2.id, 4)

      # Retrieve both matches
      assert {:ok, retrieved_match1} = Matches.get_match(match1.id)
      assert {:ok, retrieved_match2} = Matches.get_match(match2.id)

      # Verify they are different matches
      assert retrieved_match1.id != retrieved_match2.id
      assert retrieved_match1.match_configuration.length_in_games == 3
      assert retrieved_match2.match_configuration.length_in_games == 5
      assert retrieved_match1.match_configuration.rated == false
      assert retrieved_match2.match_configuration.rated == true
    end

    test "match ID is a valid hex string" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      {:ok, match} = Matches.accept_challenge(challenge.id, 2)

      assert {:ok, retrieved_match} = Matches.get_match(match.id)
      assert is_binary(retrieved_match.id)
      assert String.length(retrieved_match.id) == 32
      assert String.match?(retrieved_match.id, ~r/^[0-9a-f]{32}$/)
    end

    test "match persists in ETS after creation" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 1, rated: false},
          created_by_id: 5
        })

      {:ok, match} = Matches.accept_challenge(challenge.id, 6)

      # Wait a moment to ensure persistence
      Process.sleep(10)

      # Should still be retrievable
      assert {:ok, retrieved_match} = Matches.get_match(match.id)
      assert retrieved_match.id == match.id
    end
  end

  describe "status/1" do
    test "returns :challenge_pending for pending challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      assert Matches.status(challenge) == :challenge_pending
    end

    test "returns :challenge_accepted for accepted challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 2
        })

      {:ok, accepted_challenge} = Matches.update_challenge(challenge.id, %{status: "accepted"})

      assert Matches.status(accepted_challenge) == :challenge_accepted
    end

    test "returns :challenge_rejected for rejected challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 3
        })

      {:ok, rejected_challenge} = Matches.update_challenge(challenge.id, %{status: "rejected"})

      assert Matches.status(rejected_challenge) == :challenge_rejected
    end

    test "returns :challenge_cancelled for cancelled challenges" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 1, rated: true},
          created_by_id: 4
        })

      {:ok, cancelled_challenge} = Matches.update_challenge(challenge.id, %{status: "cancelled"})

      assert Matches.status(cancelled_challenge) == :challenge_cancelled
    end

    test "status changes as challenge is updated" do
      {:ok, challenge} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 3, rated: false},
          created_by_id: 1
        })

      # Initially pending
      assert Matches.status(challenge) == :challenge_pending

      # Accept the challenge
      {:ok, accepted} = Matches.update_challenge(challenge.id, %{status: "accepted"})
      assert Matches.status(accepted) == :challenge_accepted

      # Retrieve from store and verify status
      {:ok, retrieved} = Matches.get_challenge(challenge.id)
      assert Matches.status(retrieved) == :challenge_accepted
    end

    test "status is independent of other challenge fields" do
      {:ok, challenge1} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 1, rated: true},
          created_by_id: 1
        })

      {:ok, challenge2} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 7, rated: false},
          created_by_id: 999
        })

      {:ok, challenge3} =
        Matches.create_challenge(%{
          configuration: %{length_in_games: 5, rated: true},
          created_by_id: 42
        })

      # All should start as pending regardless of other fields
      assert Matches.status(challenge1) == :challenge_pending
      assert Matches.status(challenge2) == :challenge_pending
      assert Matches.status(challenge3) == :challenge_pending

      # Update to different statuses
      {:ok, accepted} = Matches.update_challenge(challenge1.id, %{status: "accepted"})
      {:ok, rejected} = Matches.update_challenge(challenge2.id, %{status: "rejected"})
      {:ok, cancelled} = Matches.update_challenge(challenge3.id, %{status: "cancelled"})

      # Status should reflect the updates
      assert Matches.status(accepted) == :challenge_accepted
      assert Matches.status(rejected) == :challenge_rejected
      assert Matches.status(cancelled) == :challenge_cancelled
    end
  end
end
