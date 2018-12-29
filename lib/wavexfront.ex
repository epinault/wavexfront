defmodule Wavexfront do
  @moduledoc """
  Documentation for Wavexfront.
  """

  use Application

  def start(_type, _args) do
    children =
      [{Wavexfront.Client, client_config()}]
      |> start_histogram_pool
      |> start_counter_and_gauge_pool

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp start_histogram_pool(children) do
    if histogram_enabled? do
      children ++ connection_pool_spec(:histogram)
    else
      children
    end
  end

  defp start_counter_and_gauge_pool(children) do
    if counter_and_gauge_enabled? do
      children ++ connection_pool_spec(:counter_and_gauge)
    else
      children
    end
  end

  defp connection_pool_spec(name) do
    [
      :poolboy.child_spec(
        name,
        poolboy_config(name),
        worker_config(name)
      )
    ]
  end

  defp client_config() do
    env = Application.get_all_env(:wavexfront)

    config =
      env
      |> Keyword.take([:enabled])
  end

  defp poolboy_config(name) do
    [
      {:name, {:local, name}},
      {:worker_module, Wavexfront.Proxy.Worker},
      {:size, 3},
      {:max_overflow, 1}
    ]
  end

  defp worker_config(:histogram = name) do
    default_config_parse(:histogram_proxy, 40_001)
  end

  defp worker_config(:counter_and_gauge = name) do
    default_config_parse(:counter_and_gauge_proxy, 2878)
  end

  defp default_config_parse(name, default_port) do
    config = Application.get_env(:wavexfront, name, [])

    [
      host: Keyword.get(config, :host, "localhost"),
      port: Keyword.get(config, :port, default_port),
      timeout: Keyword.get(config, :timeout, 5000)
    ]
  end

  def histogram_enabled? do
    Application.get_env(:wavexfront, :histogram_enabled, false)
  end

  def counter_and_gauge_enabled? do
    Application.get_env(:wavexfront, :counter_and_gauge_enabled, false)
  end

  def histogram_value(name, value, timestamp \\ nil, source, labels \\ []) do
    item = Wavexfront.Item.new(name, value, timestamp, source, labels)
    Wavexfront.Client.emit(item)
  end

  def gauge_value(name, value, timestamp \\ nil, source, labels \\ []) do
    item = Wavexfront.Item.new(name, value, timestamp, source, labels)
    Wavexfront.Client.emit(item)
  end

  def counter_value(name, timestamp \\ nil, source, labels \\ []) do
    item = Wavexfront.Item.new(name, 1, timestamp, source, labels)
    Wavexfront.Client.emit(item)
  end
end
