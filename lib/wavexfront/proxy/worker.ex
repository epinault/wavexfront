defmodule Wavexfront.Proxy.Worker do
  @moduledoc """
  This is the actual connection to the proxy and handle all the TCP
  aspect of sending the message to the proxy
  """
  use Connection

  require Logger

  alias Wavexfront.Item

  @initial_state %{socket: nil}

  def start_link(opts) do
    state = Map.merge(@initial_state, Enum.into(opts, %{}))
    Connection.start_link(__MODULE__, state, [])
  end

  def init(state) do
    {:connect, nil, state}
  end

  def send(conn, data), do: Connection.call(conn, {:send, data})

  def recv(conn, bytes, timeout \\ 3000) do
    Connection.call(conn, {:recv, bytes, timeout})
  end

  def close(conn), do: Connection.call(conn, :close)

  def connect(_info, state) do
    opts = [:binary, active: false]

    case :gen_tcp.connect(to_charlist(state[:host]), state[:port], opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}}

      {:error, reason} ->
        # FIXME: try again in one second. Might want to make this exponential
        # and configurable
        :error_logger.format("Connection error: ~s for ~s:~B ", [
          reason,
          state[:host],
          state[:port]
        ])

        {:backoff, 1000, state}
    end
  end

  def disconnect(info, %{socket: sock} = s) do
    :ok = :gen_tcp.close(sock)

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      {:error, :closed} ->
        :error_logger.format("Connection closed for ~s:~B ~n", [s[:host], s[:port]])

      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s for ~s:~B ", [reason, s[:host], s[:port]])
    end

    {:connect, :reconnect, %{s | socket: nil}}
  end

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:send, item}, _, %{socket: sock} = s) do
    Logger.warn(fn -> "Sending metric #{Item.to_text(item)} " end)

    case :gen_tcp.send(sock, Item.to_text(item)) do
      :ok ->
        {:reply, :ok, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call({:recv, bytes, timeout}, _, %{sock: sock} = s) do
    case :gen_tcp.recv(sock, bytes, timeout) do
      {:ok, _} = ok ->
        {:reply, ok, s}

      {:error, :timeout} = timeout ->
        {:reply, timeout, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end
end
