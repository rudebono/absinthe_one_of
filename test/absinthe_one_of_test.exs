defmodule AbsintheOneOfTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Phoenix.ConnTest, only: [json_response: 2]

  defmodule Pet do
    defmodule Cat do
      defstruct [:name, :number_of_lives]
    end

    defmodule Dog do
      defstruct [:name, :wags_tail]
    end

    defmodule Fish do
      defstruct [:name, :body_length_in_mm]
    end

    def pets(_, _, _) do
      {:ok, []}
    end

    def add(_, %{pet: %{cat: %{name: name, number_of_lives: number_of_lives}}}, _) do
      {:ok, %Cat{name: name, number_of_lives: number_of_lives}}
    end

    def add(_, %{pet: %{dog: %{name: name, wags_tail: wags_tail}}}, _) do
      {:ok, %Dog{name: name, wags_tail: wags_tail}}
    end

    def add(_, %{pet: %{fish: %{name: name, body_length_in_mm: body_length_in_mm}}}, _) do
      {:ok, %Fish{name: name, body_length_in_mm: body_length_in_mm}}
    end
  end

  defmodule TestSchema do
    use Absinthe.Schema

    @prototype_schema AbsintheOneOf.Directive

    query do
      field(:pets, list_of(:pet)) do
        resolve(&AbsintheOneOfTest.Pet.pets/3)
      end
    end

    mutation do
      field(:add, :pet) do
        arg(:pet, non_null(:pet_input))
        resolve(&AbsintheOneOfTest.Pet.add/3)
      end
    end

    union(:pet) do
      types([:cat, :dog, :fish])

      resolve_type(fn
        %AbsintheOneOfTest.Pet.Cat{}, _ -> :cat
        %AbsintheOneOfTest.Pet.Dog{}, _ -> :dog
        %AbsintheOneOfTest.Pet.Fish{}, _ -> :fish
      end)
    end

    object(:cat) do
      field(:name, non_null(:string))
      field(:number_of_lives, :integer)
    end

    object(:dog) do
      field(:name, non_null(:string))
      field(:wags_tail, :boolean)
    end

    object(:fish) do
      field(:name, non_null(:string))
      field(:body_length_in_mm, :integer)
    end

    input_object(:pet_input) do
      directive(:one_of)
      field(:cat, :cat_input)
      field(:dog, :dog_input)
      field(:fish, :fish_input)
    end

    input_object(:cat_input) do
      field(:name, non_null(:string))
      field(:number_of_lives, :integer)
    end

    input_object(:dog_input) do
      field(:name, non_null(:string))
      field(:wags_tail, :boolean)
    end

    input_object(:fish_input) do
      field(:name, non_null(:string))
      field(:body_length_in_mm, :integer)
    end
  end

  def pipeline(config, pipeline_opts) do
    config.schema_mod
    |> Absinthe.Pipeline.for_document(pipeline_opts)
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Validation.OnlyOneSubscription,
      AbsintheOneOf.Phase
    )
  end

  def call(conn) do
    conn
    |> Plug.Parsers.call(
      Plug.Parsers.init(
        parsers: [
          :urlencoded,
          :multipart,
          :json,
          Absinthe.Plug.Parser
        ],
        json_decoder: Jason
      )
    )
    |> Absinthe.Plug.call(
      Absinthe.Plug.init(
        schema: TestSchema,
        pipeline: {__MODULE__, :pipeline}
      )
    )
  end

  @mutation """
  mutation add($pet: PetInput!) {
    add(pet: $pet) {
      ... on Cat {
        name
        numberOfLives
      }
      ... on Dog {
        name
        wagsTail
      }
      ... on Fish {
        name
        bodyLengthInMm
      }
      __typename
    }
  }
  """

  test "one_of 0 input" do
    variables = %{
      "pet" => %{}
    }

    assert %{
             "errors" => [
               %{
                 "message" =>
                   "OneOf Object \"pet\" must have exactly one non-null field but got 0."
               }
             ]
           } ==
             conn(:post, "/", %{query: @mutation, variables: variables})
             |> call()
             |> json_response(200)
  end

  test "one_of 1 input" do
    variables = %{
      "pet" => %{
        "cat" => %{
          "name" => "Garfield",
          "numberOfLives" => 9
        }
      }
    }

    assert %{
             "data" => %{
               "add" => %{"__typename" => "Cat", "name" => "Garfield", "numberOfLives" => 9}
             }
           } ==
             conn(:post, "/", %{query: @mutation, variables: variables})
             |> call()
             |> json_response(200)
  end

  test "one_of 2 input" do
    variables = %{
      "pet" => %{
        "cat" => %{
          "name" => "Garfield",
          "numberOfLives" => 9
        },
        "dog" => %{
          "name" => "Odie",
          "wagsTail" => true
        }
      }
    }

    assert %{
             "errors" => [
               %{
                 "message" =>
                   "OneOf Object \"pet\" must have exactly one non-null field but got 2."
               }
             ]
           } ==
             conn(:post, "/", %{query: @mutation, variables: variables})
             |> call()
             |> json_response(200)
  end

  test "one_of 3 input" do
    variables = %{
      "pet" => %{
        "cat" => %{
          "name" => "Garfield",
          "numberOfLives" => 9
        },
        "dog" => %{
          "name" => "Odie",
          "wagsTail" => true
        },
        "fish" => %{
          "name" => "Nemo",
          "bodyLengthInMm" => 100
        }
      }
    }

    assert %{
             "errors" => [
               %{
                 "message" =>
                   "OneOf Object \"pet\" must have exactly one non-null field but got 3."
               }
             ]
           } ==
             conn(:post, "/", %{query: @mutation, variables: variables})
             |> call()
             |> json_response(200)
  end
end
