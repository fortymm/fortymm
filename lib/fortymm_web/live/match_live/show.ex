defmodule FortymmWeb.MatchLive.Show do
  use FortymmWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:match_id, id)
     |> assign(:page_title, "Match Details")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 py-12 px-4">
        <div class="max-w-4xl mx-auto">
          <div class="bg-white/10 backdrop-blur-lg rounded-2xl shadow-2xl p-8 border border-white/20">
            <h1 class="text-4xl font-bold text-white mb-2">
              Match #{@match_id}
            </h1>
            <p class="text-purple-200">
              Match details coming soon
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
