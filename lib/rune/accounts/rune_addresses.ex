defmodule Rune.RuneAddresses do

  use GenServer

  @url "https://explorer.binance.org/api/v1"
  @page_limit 1000

  @initial_interval 250
  @interval 6*60*60*1000 #every 6 hrs update
  @jitter 20


  def get_frozen_rune_accounts do
    account_balances = GenServer.call(__MODULE__, :get_account_balances)
    account_balances
    |> Enum.filter(fn a ->
        Enum.find(a["balance"], & &1["asset"] == "RUNE-B1A" && &1["frozen"] > 0)
    end)
  end

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end


  def init(_args) do
    Process.send_after(self(), :work, @initial_interval)
    {:ok, nil}
  end

  def handle_call(:get_account_balances, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:work, _state) do
    Process.send_after(self(), :work, @interval + :rand.uniform(@jitter))
    IO.puts("Getting account balances....")
    acct_balances = get_accounts_with_balances()
    IO.puts("Done fetching account balances...")
    IO.inspect(acct_balances)
    {:noreply, acct_balances}
  end

  def get_accounts_with_balances() do
    {num_holders, holder_list} = get_page(1)
    num_pages = ceil(num_holders/@page_limit)
    hlist =  2..num_pages |> Enum.reduce([holder_list], fn x, acc ->
        {_num, holders} = get_page(x)
        [acc | holders]
      end)
      |> List.flatten()
    IO.puts("full list length #{length(hlist)}")
    hlist
      |> Enum.reduce([], fn a, acc ->
          :timer.sleep(1000)
          balance = get_balances(a["address"])
          [acc | [balance]]
        end)
      |> List.flatten
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
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =  HTTPoison.get("#{@url}/balances/#{account}")
    Jason.decode!(body)
  end
end


