defmodule Rune.RuneAddresses do

  use GenServer

  @url "https://explorer.binance.org/api/v1"
  @page_limit 1000

  @initial_interval 250
  @interval 24*60*60*1000 #every 24 hrs update


  def get_frozen_rune_accounts do
    account_balances = GenServer.call(__MODULE__, :get_account_balances)
    account_balances["data"]
    |> Enum.filter(fn a ->
        a["frozen"] > 0
    end)
  end

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end


  def init(_args) do
    Process.send_after(self(), :work, @initial_interval)
    {:ok, %{"started" => nil, "ended" => nil, "data" => nil}}
  end

  def handle_call(:get_account_balances, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:work, _state) do
    IO.puts("Getting account balances....")
    started = DateTime.utc_now()
    acct_balances = get_accounts_with_balances()
    ended = DateTime.utc_now()
    IO.puts("Done fetching account balances...")
    Process.send_after(self(), :work, @interval)
    {:noreply, %{"started" => started, "ended" => ended, "data" => acct_balances} }
  end

  def handle_info(_, state) do
     {:noreply, state}
  end

  def get_accounts_with_balances() do
    {num_holders, holder_list} = get_page(1)
    num_pages = ceil(num_holders/@page_limit)
    hlist =  2..num_pages |> Enum.reduce([holder_list], fn x, acc ->
        {_num, holders} = get_page(x)
        [acc | holders]
      end)
      |> List.flatten()
    hlist
      |> Enum.take(3)
      |> Enum.reduce([], fn a, acc ->
          balance = get_balances(a["address"])
          b = balance["balance"] |> Enum.find(& &1["asset"] == "RUNE-B1A")
          rune_balance = %{"address" => balance["address"], "asset" => b["asset"], "free" => b["free"], "frozen" => b["frozen"]}
          [rune_balance | acc]
        end)
  end

  defp get_page(page_num) do
  {:ok, %HTTPoison.Response{status_code: 200, body: body}} =  HTTPoison.get("#{@url}/asset-holders?page=#{page_num}&rows=1000&asset=RUNE-B1A")
   holders  = Jason.decode!(body)
   total_num = holders["totalNum"]
   addr_holders = holders["addressHolders"]
   {total_num, addr_holders}
  end

  def get_balances(account) do
    IO.puts("fetching balance for account #{account}")
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 10000]
    headers = ["Accept": "Application/json; Charset=utf-8"]
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =  HTTPoison.get("#{@url}/balances/#{account}", headers, options)
    Jason.decode!(body)
  end
end


