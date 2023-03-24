defmodule Virtfs.GenBehaviour do
  def gen(behaviour_mod) do
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
