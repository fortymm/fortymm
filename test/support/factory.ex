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
end
