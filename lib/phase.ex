defmodule AbsintheOneOf.Phase do
  @moduledoc false

  @behaviour Absinthe.Phase

  @impl true
  @spec run(
          blueprint :: Absinthe.Blueprint.node_t(),
          config :: any()
        ) :: {:ok, Absinthe.Blueprint.node_t()}
  def run(blueprint, _config) do
    {:ok, Absinthe.Blueprint.prewalk(blueprint, &prewalk/1)}
  end

  @spec prewalk(node :: Absinthe.Blueprint.node_t()) :: Absinthe.Blueprint.node_t()
  defp prewalk(%Absinthe.Blueprint.Input.Argument{} = node) do
    case find_invalid(node) do
      {nil, 0} ->
        node

      {name, count} ->
        Absinthe.Phase.put_error(node, error(name, count))
    end
  end

  defp prewalk(node), do: node

  @spec find_invalid(node :: map()) :: {nil | String.t(), integer()}
  defp find_invalid(
         %{
           input_value: %Absinthe.Blueprint.Input.Value{
             normalized: %Absinthe.Blueprint.Input.List{items: items}
           }
         } = node
       ) do
    Enum.reduce_while(
      items,
      {nil, 0},
      fn item, {name, count} ->
        if name do
          {:halt, {name, count}}
        else
          {:cont, find_invalid(%{name: node.name, input_value: item})}
        end
      end
    )
  end

  defp find_invalid(
         %{
           input_value: %Absinthe.Blueprint.Input.Value{
             normalized: %Absinthe.Blueprint.Input.Object{fields: fields}
           }
         } = node
       ) do
    Enum.reduce_while(
      fields,
      if valid?(node) do
        {nil, 0}
      else
        {node.name, Enum.count(fields)}
      end,
      fn field, {name, count} ->
        if name do
          {:halt, {name, count}}
        else
          {:cont, find_invalid(field)}
        end
      end
    )
  end

  defp find_invalid(_node), do: {nil, 0}

  @spec valid?(node :: Absinthe.Blueprint.node_t()) :: boolean()
  defp valid?(
         %{
           input_value: %Absinthe.Blueprint.Input.Value{
             normalized: %Absinthe.Blueprint.Input.Object{
               schema_node: %{} = schema_node,
               fields: fields
             }
           }
         } = _node
       ) do
    schema_node = Absinthe.Type.unwrap(schema_node)
    private = Map.get(schema_node, :__private__, [])
    !(Keyword.get(private, :one_of, false) && Enum.count(fields) != 1)
  end

  defp valid?(_node), do: true

  @spec error(name :: String.t(), count :: integer()) :: Absinthe.Phase.Error.t()
  defp error(name, count) do
    %Absinthe.Phase.Error{
      phase: __MODULE__,
      message: "OneOf Object \"#{name}\" must have exactly one non-null field but got #{count}."
    }
  end
end
