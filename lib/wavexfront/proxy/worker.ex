defmodule Wavexfront.Proxy.Worker do
  @moduledoc """
  This is the actual connection to the proxy and handle all the TCP
  aspect of sending the message to the proxy
  """
  use Connection

  alias Wavexfront.Item

  @initial_state %{socket: nil}

  def start_link(opts) do
    state = Map.merge(@initial_state, Enum.into(opts, %{}))
    Connection.start_link(__MODULE__, state, [])
  end

  def init(state) do
    {:connect, nil, state}
  end

  def connect(_info, state) do
    opts = [:binary, active: false]

    case :gen_tcp.connect(to_char_list(state[:host]), state[:port], opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}}

      {:error, reason} ->
        IO.puts("TCP connection error: #{inspect(reason)}")
        # try again in one second
        {:backoff, 1000, state}
    end
  end

  def disconnect(info, %{socket: sock} = s) do
    :ok = :gen_tcp.close(sock)

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])

      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s~n", [reason])
    end

    {:connect, :reconnect, %{s | socket: nil}}
  end

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:send, item}, _, %{socket: sock} = s) do
    case :gen_tcp.send(sock, Item.to_text(item)) do
      :ok ->
        {:reply, :ok, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end
end
