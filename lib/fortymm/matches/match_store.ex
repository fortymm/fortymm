defmodule Fortymm.Matches.MatchStore do
  @moduledoc """
  ETS-backed storage for matches.
  """

  @table_name :matches

  @doc """
  Starts the ETS table for storing matches.
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
  Inserts a match into the ETS table.
  """
  def insert(id, match) do
    :ets.insert(@table_name, {id, match})
    :ok
  end

  @doc """
  Retrieves a match from the ETS table by ID.
  """
  def get(id) do
    case :ets.lookup(@table_name, id) do
      [{^id, match}] -> {:ok, match}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Deletes a match from the ETS table by ID.
  """
  def delete(id) do
    :ets.delete(@table_name, id)
    :ok
  end

  @doc """
  Lists all matches in the ETS table.
  """
  def list_all do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, match} -> match end)
  end

  @doc """
  Clears all matches from the ETS table.
  Useful for testing.
  """
  def clear do
    :ets.delete_all_objects(@table_name)
    :ok
  end
end
