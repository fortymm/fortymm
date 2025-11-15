defmodule Fortymm.Matches.MatchUpdates do
  @moduledoc """
  PubSub interface for broadcasting and subscribing to match updates.
  """

  alias Phoenix.PubSub

  @pubsub Fortymm.PubSub

  @doc """
  Broadcasts a match update to all subscribers.

  ## Examples

      iex> broadcast(%Match{id: "abc123"})
      :ok

  """
  def broadcast(%{id: id} = match) do
    PubSub.broadcast(@pubsub, topic(id), {:match_updated, match})
  end

  @doc """
  Subscribes the current process to updates for a specific match.

  ## Examples

      iex> subscribe("abc123")
      :ok

  """
  def subscribe(match_id) do
    PubSub.subscribe(@pubsub, topic(match_id))
  end

  defp topic(match_id), do: "match:#{match_id}"
end
