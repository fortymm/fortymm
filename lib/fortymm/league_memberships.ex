defmodule Fortymm.LeagueMemberships do
  @moduledoc """
  The LeagueMemberships context.
  """

  import Ecto.Query, warn: false
  alias Fortymm.Repo

  alias Fortymm.LeagueMemberships.LeagueMembership

  @doc """
  Returns the list of league_memberships.

  ## Examples

      iex> list_league_memberships()
      [%LeagueMembership{}, ...]

  """
  def list_league_memberships do
    Repo.all(LeagueMembership)
  end

  @doc """
  Gets a single league_membership.

  Raises `Ecto.NoResultsError` if the League membership does not exist.

  ## Examples

      iex> get_league_membership!(123)
      %LeagueMembership{}

      iex> get_league_membership!(456)
      ** (Ecto.NoResultsError)

  """
  def get_league_membership!(id), do: Repo.get!(LeagueMembership, id)

  @doc """
  Creates a league_membership.

  ## Examples

      iex> create_league_membership(%{field: value})
      {:ok, %LeagueMembership{}}

      iex> create_league_membership(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_league_membership(attrs \\ %{}) do
    %LeagueMembership{}
    |> LeagueMembership.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a league_membership.

  ## Examples

      iex> update_league_membership(league_membership, %{field: new_value})
      {:ok, %LeagueMembership{}}

      iex> update_league_membership(league_membership, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_league_membership(%LeagueMembership{} = league_membership, attrs) do
    league_membership
    |> LeagueMembership.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a league_membership.

  ## Examples

      iex> delete_league_membership(league_membership)
      {:ok, %LeagueMembership{}}

      iex> delete_league_membership(league_membership)
      {:error, %Ecto.Changeset{}}

  """
  def delete_league_membership(%LeagueMembership{} = league_membership) do
    Repo.delete(league_membership)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking league_membership changes.

  ## Examples

      iex> change_league_membership(league_membership)
      %Ecto.Changeset{data: %LeagueMembership{}}

  """
  def change_league_membership(%LeagueMembership{} = league_membership, attrs \\ %{}) do
    LeagueMembership.changeset(league_membership, attrs)
  end
end
