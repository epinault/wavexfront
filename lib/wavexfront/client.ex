defmodule Wavexfront.Client do
  @moduledoc false

  use GenServer

  require Logger

  alias Wavexfront.Item

  @name __MODULE__
  @timeout 5000

  ## GenServer state
  defstruct [:proxy, :enabled]

  ## Public API

  def start_link(config) do
    state = %__MODULE__{
      proxy: config[:proxy],
      enabled: config[:enabled]
    }

    GenServer.start_link(__MODULE__, state, name: @name)
  end

  def emit(%Item{} = item) do
    if pid = Process.whereis(@name) do
      GenServer.cast(pid, {:emit, item})
    else
      Logger.warn(
        "(Wavexfront) Trying to report metrics but the :wavesfront application has not been started",
        wavexfront: false
      )
    end
  end

  ## GenServer callbacks

  def init(state) do
    Logger.metadata(wavexfront: false)
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def handle_cast({:emit, _item}, %{enabled: false} = state) do
    {:noreply, state}
  end

  def handle_cast({:emit, item}, %{enabled: :log} = state) do
    Logger.info(["(Wavexfront) sending metric to log only: ", Item.to_text(item)])
    {:noreply, state}
  end

  def handle_cast({:emit, item}, %{enabled: true} = state) do
    pool_name = select_pool(item)

    :poolboy.transaction(
      pool_name,
      fn pid -> GenServer.call(pid, {:send, item}) end,
      @timeout
    )

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.info("(Wavexfront) unexpected message: #{inspect(message)}")
    {:noreply, state}
  end

  defp select_pool(item) do
    case item.type do
      :histogram -> :histogram
      _ -> :counter_and_gauge
    end
  end
end
