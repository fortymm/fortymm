defmodule FortymmWeb.MatchLive.ScoreEntry do
  use FortymmWeb, :live_view

  @impl true
  def mount(%{"match_id" => match_id, "id" => game_id}, _session, socket) do
    {:ok,
     socket
     |> assign(:match_id, match_id)
     |> assign(:game_id, game_id)
     |> assign(:page_title, "Enter Score")
     |> assign(:form, to_form(%{}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 py-12 px-4">
        <div class="max-w-2xl mx-auto">
          <div class="bg-white/10 backdrop-blur-lg rounded-2xl shadow-2xl p-8 border border-white/20">
            <h1 class="text-3xl font-bold text-white mb-2">
              Enter Score
            </h1>
            <p class="text-purple-200 mb-8">
              Match #{@match_id} - Game #{@game_id}
            </p>

            <.form for={@form} id="score-form" phx-submit="save" class="space-y-6">
              <%!-- Empty form placeholder - to be implemented --%>
              <div class="bg-white/5 rounded-lg p-6 border border-white/10">
                <p class="text-purple-100 text-center">
                  Score entry form coming soon
                </p>
              </div>

              <div class="flex gap-4">
                <button
                  type="submit"
                  class="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 text-white font-semibold py-3 px-6 rounded-lg hover:from-purple-600 hover:to-pink-600 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
                >
                  Save Score
                </button>
                <.link
                  navigate={~p"/dashboard"}
                  class="flex-1 bg-white/10 text-white font-semibold py-3 px-6 rounded-lg hover:bg-white/20 transition-all duration-200 text-center border border-white/20"
                >
                  Cancel
                </.link>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("save", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Score saving coming soon!")
     |> push_navigate(to: ~p"/dashboard")}
  end
end
