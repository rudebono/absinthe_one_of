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

      {invalid_node, count} ->
        Absinthe.Phase.put_error(node, error(invalid_node, count))
    end
  end

  defp prewalk(node), do: node

  @spec find_invalid(node :: Absinthe.Blueprint.node_t()) ::
          {nil | Absinthe.Blueprint.node_t(), integer()}
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
      fn item, {invalid_node, count} ->
        if invalid_node do
          {:halt, {invalid_node, count}}
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
        {node, Enum.count(fields)}
      end,
      fn field, {invalid_node, count} ->
        if invalid_node do
          {:halt, {invalid_node, count}}
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

  @spec error(node :: Absinthe.Blueprint.node_t(), count :: integer()) :: Absinthe.Phase.Error.t()
  defp error(node, count) do
    %Absinthe.Phase.Error{
      phase: __MODULE__,
      message:
        "OneOf Object \"#{node.name}\" must have exactly one non-null field but got #{count}."
    }
  end
end
