defmodule Fortymm.Matches.ChallengeStore do
  @moduledoc """
  ETS-backed storage for challenges.
  """

  @table_name :challenges

  @doc """
  Starts the ETS table for storing challenges.
  """
  def start_link do
    :ets.new(@table_name, [:set, :public, :named_table])
    {:ok, self()}
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent
    }
  end

  @doc """
  Inserts a challenge into the ETS table.
  """
  def insert(id, challenge) do
    :ets.insert(@table_name, {id, challenge})
    :ok
  end

  @doc """
  Retrieves a challenge from the ETS table by ID.
  """
  def get(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, challenge}] -> {:ok, challenge}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Deletes a challenge from the ETS table by ID.
  """
  def delete(id) do
    :ets.delete(@table_name, id)
    :ok
  end

  @doc """
  Lists all challenges in the ETS table.
  """
  def list_all do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, challenge} -> challenge end)
  end

  @doc """
  Clears all challenges from the ETS table.
  Useful for testing.
  """
  def clear do
    :ets.delete_all_objects(@table_name)
    :ok
  end
end
