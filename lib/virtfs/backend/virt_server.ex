defmodule Virtfs.Backend.VirtServer do
  use GenServer
  alias Virtfs.FS

  def start_link(%FS{} = fs) do
    GenServer.start_link(__MODULE__, fs)
  end

  def ls(pid, path \\ "") do
    GenServer.call(pid, {:ls, path})
  end

  @impl true
  def init(%FS{} = fs) do
    {:ok, fs}
  end

  @impl true
  def handle_call({:ls, _path}, _from, %FS{} = fs) do
    {:reply, [], fs}
  end
end
