defmodule Exintegrate do
  use GenServer
  @moduledoc """
  Documentation for `Exintegrate`.
  """
    ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Server Callbacks
  def init(:ok) do
    {:ok, some_syscall()}
  end

  def some_syscall() do
    IO.puts("HELLO")
  end
end
