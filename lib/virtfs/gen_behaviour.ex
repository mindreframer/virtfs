defmodule Virtfs.GenBehaviour do
  defmacro __using__(_) do
    quote do
      require Virtfs.GenBehaviour
      Virtfs.GenBehaviour.gen()
    end
  end

  defmacro gen() do
    callbacks = extract_callbacks(Virtfs.Behaviour)

    for callback <- callbacks do
      gen_callback(callback)
    end
  end

  def gen_callback({fn_name, _arity, args}) do
    first_arg = Enum.at(args, 0)
    prepared_args = Enum.map(args, &wrap_in_elixir/1)

    quote do
      def unquote(fn_name)(unquote_splicing(prepared_args)) do
        unquote(wrap_in_elixir(first_arg)).backend.unquote(fn_name)(
          unquote_splicing(prepared_args)
        )
      end
    end
  end

  def wrap_in_elixir(arg_name) do
    {arg_name, [], Elixir}
  end

  def extract_callbacks(behaviour_mod) do
    {:ok, callbacks} = Code.Typespec.fetch_callbacks(behaviour_mod)
    Enum.map(callbacks, &extract_from_callback/1)
  end

  def extract_from_callback(callback) do
    {{fn_name, fn_arity},
     [
       {:type, _, :fun,
        [
          {:type, _, :product, args},
          _
        ]}
     ]} = callback

    {fn_name, fn_arity, extract_args(args)}
  end

  def extract_args(args) do
    Enum.map(args, &extract_arg_name/1)
  end

  def extract_arg_name(arg) do
    {:ann_type, _, [{:var, _, var_name}, _]} = arg
    var_name
  end
end
