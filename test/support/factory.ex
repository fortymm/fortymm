defmodule Fortymm.Factory do
  use ExMachina.Ecto, repo: Fortymm.Repo

  def player_factory do
    %Fortymm.Players.Player{
      first_name: sequence(:player_first_name, &"player-first-name-#{&1}"),
      last_name: sequence(:player_last_name, &"player-last-name-#{&1}")
    }
  end

  def league_factory do
    %Fortymm.Leagues.League{
      name: sequence(:league_name, &"league-name-#{&1}"),
      slug: sequence(:league_slug, &"league-slug-#{&1}")
    }
  end

  def league_membership_factory do
    %Fortymm.LeagueMemberships.LeagueMembership{
      player_id: nil,
      league_id: nil,
      external_league_ref:
        sequence(
          :league_membership_external_league_ref,
          &"league-membership-external-league-ref-#{&1}"
        )
    }
  end

  def with_player(model, attrs \\ %{}) do
    player = insert(:player, attrs)

    Enum.into(%{player_id: player.id}, model)
  end

  def with_league(model, attrs \\ %{}) do
    league = insert(:league, attrs)

    Enum.into(%{league_id: league.id}, model)
  end
end
