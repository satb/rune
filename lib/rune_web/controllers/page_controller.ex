defmodule RuneWeb.PageController do
  use RuneWeb, :controller
  alias Rune.RuneAddresses

  def index(conn, _params) do
    frozen_accts = RuneAddresses.get_frozen_rune_accounts()
    render(conn, "index.html", frozen_accts: frozen_accts)
  end
end
