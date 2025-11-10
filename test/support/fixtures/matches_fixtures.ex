defmodule Fortymm.MatchesFixtures do
  @moduledoc """
  This module defines test helpers for creating matches via ETS.
  """

  alias Fortymm.Matches.{Match, MatchStore, Configuration, Participant}

  def match_fixture(attrs \\ %{}) do
    default_attrs = %{
      match_configuration: %Configuration{
        length_in_games: 3
      },
      participants: [
        %Participant{user_id: 1, participant_number: 1},
        %Participant{user_id: 2, participant_number: 2}
      ],
      status: "pending"
    }

    attrs = Enum.into(attrs, default_attrs)
    match = struct!(Match, attrs)

    # Generate an ID for the match
    id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    match = %{match | id: id}

    # Store in ETS
    MatchStore.insert(id, match)
    match
  end

  def match_with_status_fixture(status, attrs \\ %{}) do
    match_fixture(Enum.into(attrs, %{status: status}))
  end

  def pending_match_fixture(attrs \\ %{}) do
    match_with_status_fixture("pending", attrs)
  end

  def in_progress_match_fixture(attrs \\ %{}) do
    match_with_status_fixture("in_progress", attrs)
  end

  def complete_match_fixture(attrs \\ %{}) do
    match_with_status_fixture("complete", attrs)
  end

  def canceled_match_fixture(attrs \\ %{}) do
    match_with_status_fixture("canceled", attrs)
  end

  def aborted_match_fixture(attrs \\ %{}) do
    match_with_status_fixture("aborted", attrs)
  end
end
