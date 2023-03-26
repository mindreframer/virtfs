defmodule Virtfs.Server do
  use GenServer
  alias Virtfs.FS
  alias Virtfs.Backend

  ###
  ### API
  ###

  def start_link() do
    start_link(FS.init())
  end

  def start_link(%FS{} = fs) do
    GenServer.start_link(__MODULE__, fs)
  end

  def ls(pid, path \\ "") do
    GenServer.call(pid, {:ls, path})
  end

  def ls!(pid, path \\ "") do
    handle_error(ls(pid, path), {:ls!, path})
  end

  def write(pid, path, content) do
    GenServer.call(pid, {:write, path, content})
  end

  def write!(pid, path, content) do
    handle_error(write(pid, path, content), {:write!, path, content})
  end

  def read(pid, path) do
    GenServer.call(pid, {:read, path})
  end

  def read!(pid, path) do
    handle_error(read(pid, path), {:read!, path})
  end

  def mkdir_p(pid, path) do
    GenServer.call(pid, {:mkdir_p, path})
  end

  def mkdir_p!(pid, path) do
    handle_error(mkdir_p(pid, path), {:mkdir_p!, path})
  end

  def rm(pid, path) do
    GenServer.call(pid, {:rm, path})
  end

  def rm!(pid, path) do
    handle_error(rm(pid, path), {:rm!, path})
  end

  def rename(pid, src, dest) do
    GenServer.call(pid, {:rename, src, dest})
  end

  def rename!(pid, src, dest) do
    handle_error(rename(pid, src, dest), {:rename!, src, dest})
  end

  def rm_rf(pid, path) do
    GenServer.call(pid, {:rm_rf, path})
  end

  def rm_rf!(pid, path) do
    handle_error(rm_rf(pid, path), {:rm_rf!, path})
  end

  def cp(pid, src, dest) do
    GenServer.call(pid, {:cp, src, dest})
  end

  def cp!(pid, src, dest) do
    handle_error(cp(pid, src, dest), {:cp!, src, dest})
  end

  def cp_r(pid, src, dest) do
    GenServer.call(pid, {:cp_r, src, dest})
  end

  def cp_r!(pid, src, dest) do
    handle_error(cp_r(pid, src, dest), {:cp_r!, src, dest})
  end

  def tree(pid, path) do
    GenServer.call(pid, {:tree, path})
  end

  def tree!(pid, path) do
    handle_error(tree(pid, path), {:tree!, path})
  end

  def cd(pid, path) do
    GenServer.call(pid, {:cd, path})
  end

  def cd!(pid, path) do
    handle_error(cd(pid, path), {:cd!, path})
  end

  def exists?(pid, path) do
    GenServer.call(pid, {:exists?, path})
  end

  def exists!(pid, path) do
    handle_error(exists?(pid, path), {:exists!, path})
  end

  def dir?(pid, path) do
    GenServer.call(pid, {:dir?, path})
  end

  def dir!(pid, path) do
    handle_error(dir?(pid, path), {:dir!, path})
  end

  ###
  ### GEN SERVER CALLBACKS
  ###

  @impl true
  def init(%FS{} = fs) do
    {:ok, fs}
  end

  @impl true
  def handle_call({:ls, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.ls(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:write, path, content}, _from, %FS{} = fs) do
    {fs, res} = Backend.write(fs, path, content)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:read, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.read(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:mkdir_p, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.mkdir_p(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:rm, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.rm(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:rm_rf, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.rm_rf(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:tree, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.tree(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:cp, src, dest}, _from, %FS{} = fs) do
    {fs, res} = Backend.cp(fs, src, dest)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:cp_r, src, dest}, _from, %FS{} = fs) do
    {fs, res} = Backend.cp_r(fs, src, dest)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:rename, src, dest}, _from, %FS{} = fs) do
    {fs, res} = Backend.rename(fs, src, dest)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:cd, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.cd(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:exists?, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.exists?(fs, path)
    {:reply, res, fs}
  end

  @impl true
  def handle_call({:dir?, path}, _from, %FS{} = fs) do
    {fs, res} = Backend.dir?(fs, path)
    {:reply, res, fs}
  end

  defp handle_error(res, args) do
    case res do
      {:error, _} -> raise(inspect({res, args}))
      {:ok, res} -> res
      :ok -> :ok
    end
  end
end
