defmodule Parent do
  @moduledoc false
  alias Parent.State
  use Parent.PublicTypes

  @spec initialize() :: :ok
  def initialize() do
    if initialized?(), do: raise("Parent state is already initialized")
    Process.put(__MODULE__, State.initialize())
    :ok
  end

  @spec initialized?() :: boolean
  def initialized?(), do: not is_nil(Process.get(__MODULE__))

  @spec start_child(child_spec | module | {module, term}) :: on_start_child
  def start_child(child_spec) do
    with result <- State.start_child(state(), child_spec),
         {:ok, pid, state} <- result do
      store(state)
      {:ok, pid}
    end
  end

  @spec shutdown_child(id) :: :ok
  def shutdown_child(child_id) do
    state = State.shutdown_child(state(), child_id)
    store(state)
    :ok
  end

  @spec shutdown_all(term) :: :ok
  def shutdown_all(reason) do
    state = State.shutdown_all(state(), reason)
    store(state)
    :ok
  end

  @spec handle_message(term) :: State.child_exit_message() | :error | :ignore
  def handle_message(message) do
    with {result, state} <- State.handle_message(state(), message) do
      store(state)
      result
    end
  end

  @spec await_termination(id, non_neg_integer() | :infinity) ::
          {pid, child_meta, reason :: term} | :timeout
  def await_termination(child_id, timeout) do
    with {result, state} <- State.await_termination(state(), child_id, timeout) do
      store(state)
      result
    end
  end

  @spec entries :: [child]
  def entries(), do: State.entries(state())

  @spec supervisor_which_children() :: [{term(), pid(), :worker, [module()] | :dynamic}]
  def supervisor_which_children(), do: State.supervisor_which_children(state())

  @spec supervisor_count_children() :: [
          specs: non_neg_integer,
          active: non_neg_integer,
          supervisors: non_neg_integer,
          workers: non_neg_integer
        ]
  def supervisor_count_children(), do: State.supervisor_count_children(state())

  @spec size() :: non_neg_integer
  def size(), do: State.size(state())

  @spec id(pid) :: {:ok, id} | :error
  def id(pid), do: State.id(state(), pid)

  @spec pid(id) :: {:ok, pid} | :error
  def pid(id), do: State.pid(state(), id)

  @spec meta(id) :: {:ok, child_meta} | :error
  def meta(id), do: State.meta(state(), id)

  @spec update_meta(id, (child_meta -> child_meta)) :: :ok | :error
  def update_meta(id, updater) do
    with {:ok, new_state} <- State.update_meta(state(), id, updater) do
      store(new_state)
      :ok
    end
  end

  @spec state() :: State.t()
  defp state() do
    state = Process.get(__MODULE__)
    if is_nil(state), do: raise("#{__MODULE__} is not initialized")
    state
  end

  defp store(state), do: Process.put(__MODULE__, state)
end
