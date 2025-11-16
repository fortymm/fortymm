defmodule Fortymm.Matches.MatchUpdatesTest do
  use ExUnit.Case, async: true

  alias Fortymm.Matches.MatchUpdates
  alias Fortymm.Matches.Match

  describe "subscribe/1" do
    test "subscribes the current process to match updates" do
      match_id = "test-match-123"

      assert :ok = MatchUpdates.subscribe(match_id)

      # Verify subscription by broadcasting and receiving a message
      match = %Match{
        id: match_id,
        status: "pending",
        participants: [],
        games: [],
        match_configuration: %{}
      }

      MatchUpdates.broadcast(match)
      assert_receive {:match_updated, ^match}
    end

    test "multiple processes can subscribe to the same match" do
      match_id = "test-match-456"

      # Subscribe from current process
      MatchUpdates.subscribe(match_id)

      parent = self()

      # Subscribe from another process
      task =
        Task.async(fn ->
          MatchUpdates.subscribe(match_id)
          send(parent, :subscribed)

          receive do
            {:match_updated, match} ->
              send(parent, {:task_received, match})
          after
            1000 -> send(parent, :task_timeout)
          end
        end)

      # Wait for task to subscribe
      assert_receive :subscribed

      # Broadcast a message
      match = %Match{
        id: match_id,
        status: "in_progress",
        participants: [],
        games: [],
        match_configuration: %{}
      }

      MatchUpdates.broadcast(match)

      # Both processes should receive
      assert_receive {:match_updated, ^match}
      assert_receive {:task_received, ^match}

      Task.shutdown(task)
    end
  end

  describe "broadcast/1" do
    test "broadcasts match update to all subscribers" do
      match = %Match{
        id: "broadcast-test-123",
        status: "in_progress",
        participants: [],
        games: [],
        match_configuration: %{}
      }

      # Subscribe to the match
      MatchUpdates.subscribe(match.id)

      # Broadcast the update
      assert :ok = MatchUpdates.broadcast(match)

      # Verify we received the message
      assert_receive {:match_updated, ^match}
    end

    test "broadcasts to multiple subscribers" do
      match = %Match{
        id: "broadcast-test-456",
        status: "complete",
        participants: [],
        games: [],
        match_configuration: %{}
      }

      # Subscribe from current process
      MatchUpdates.subscribe(match.id)

      # Subscribe from another process
      parent = self()

      task =
        Task.async(fn ->
          MatchUpdates.subscribe(match.id)
          send(parent, :subscribed)

          receive do
            {:match_updated, received_match} ->
              send(parent, {:task_received, received_match})
          after
            1000 -> send(parent, :timeout)
          end
        end)

      # Wait for task to subscribe
      assert_receive :subscribed

      # Broadcast the update
      MatchUpdates.broadcast(match)

      # Both processes should receive the update
      assert_receive {:match_updated, ^match}
      assert_receive {:task_received, ^match}

      Task.shutdown(task)
    end

    test "does not send to unsubscribed processes" do
      match = %Match{
        id: "broadcast-test-789",
        status: "pending",
        participants: [],
        games: [],
        match_configuration: %{}
      }

      # Don't subscribe, just broadcast
      MatchUpdates.broadcast(match)

      # Should not receive any message
      refute_receive {:match_updated, _}, 100
    end

    test "broadcasts to correct topic only" do
      match1 = %Match{
        id: "match-1",
        status: "in_progress",
        participants: [],
        games: [],
        match_configuration: %{}
      }

      match2 = %Match{
        id: "match-2",
        status: "in_progress",
        participants: [],
        games: [],
        match_configuration: %{}
      }

      # Subscribe only to match1
      MatchUpdates.subscribe(match1.id)

      # Broadcast update to match2
      MatchUpdates.broadcast(match2)

      # Should not receive match2 update
      refute_receive {:match_updated, ^match2}, 100

      # Now broadcast to match1
      MatchUpdates.broadcast(match1)

      # Should receive match1 update
      assert_receive {:match_updated, ^match1}
    end
  end
end
