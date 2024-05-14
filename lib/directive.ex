defmodule AbsintheOneOf.Directive do
  @moduledoc false

  use Absinthe.Schema.Prototype

  directive :one_of do
    on([:input_object])
    expand(&expand_one_of/2)
  end

  @spec expand_one_of(
          arguments :: %{},
          node :: Absinthe.Blueprint.Schema.InputObjectTypeDefinition.t()
        ) :: Absinthe.Blueprint.Schema.InputObjectTypeDefinition.t()
  defp expand_one_of(_arguments, %Absinthe.Blueprint.Schema.InputObjectTypeDefinition{} = node) do
    %{node | __private__: Keyword.put(node.__private__, :one_of, true)}
  end
end
