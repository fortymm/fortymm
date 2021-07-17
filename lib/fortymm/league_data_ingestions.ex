defmodule Fortymm.LeagueDataIngestions do
  @moduledoc """
  The LeagueDataIngestions context.
  """

  import Ecto.Query, warn: false
  alias Fortymm.Repo

  alias Fortymm.LeagueDataIngestions.LeagueDataIngestion

  @doc """
  Returns the list of league_data_ingestions.

  ## Examples

      iex> list_league_data_ingestions()
      [%LeagueDataIngestion{}, ...]

  """
  def list_league_data_ingestions do
    Repo.all(LeagueDataIngestion)
  end

  @doc """
  Gets a single league_data_ingestion.

  Raises `Ecto.NoResultsError` if the League data ingestion does not exist.

  ## Examples

      iex> get_league_data_ingestion!(123)
      %LeagueDataIngestion{}

      iex> get_league_data_ingestion!(456)
      ** (Ecto.NoResultsError)

  """
  def get_league_data_ingestion!(id), do: Repo.get!(LeagueDataIngestion, id)

  @doc """
  Creates a league_data_ingestion.

  ## Examples

      iex> create_league_data_ingestion(%{field: value})
      {:ok, %LeagueDataIngestion{}}

      iex> create_league_data_ingestion(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_league_data_ingestion(attrs \\ %{}) do
    %LeagueDataIngestion{}
    |> LeagueDataIngestion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a league_data_ingestion.

  ## Examples

      iex> update_league_data_ingestion(league_data_ingestion, %{field: new_value})
      {:ok, %LeagueDataIngestion{}}

      iex> update_league_data_ingestion(league_data_ingestion, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_league_data_ingestion(%LeagueDataIngestion{} = league_data_ingestion, attrs) do
    league_data_ingestion
    |> LeagueDataIngestion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a league_data_ingestion.

  ## Examples

      iex> delete_league_data_ingestion(league_data_ingestion)
      {:ok, %LeagueDataIngestion{}}

      iex> delete_league_data_ingestion(league_data_ingestion)
      {:error, %Ecto.Changeset{}}

  """
  def delete_league_data_ingestion(%LeagueDataIngestion{} = league_data_ingestion) do
    Repo.delete(league_data_ingestion)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking league_data_ingestion changes.

  ## Examples

      iex> change_league_data_ingestion(league_data_ingestion)
      %Ecto.Changeset{data: %LeagueDataIngestion{}}

  """
  def change_league_data_ingestion(%LeagueDataIngestion{} = league_data_ingestion, attrs \\ %{}) do
    LeagueDataIngestion.changeset(league_data_ingestion, attrs)
  end
end
