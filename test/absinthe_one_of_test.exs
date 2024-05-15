defmodule AbsintheOneOfTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Phoenix.ConnTest, only: [json_response: 2]

  defmodule Owner do
    defmodule Person do
      defstruct [:name, :age]
    end

    defmodule Organization do
      defstruct [:name, :registration_number]
    end

    def add(%{person: %{name: name, age: age}}) do
      {:ok, %Person{name: name, age: age}}
    end

    def add(%{organization: %{name: name, registration_number: registration_number}}) do
      {:ok, %Organization{name: name, registration_number: registration_number}}
    end
  end

  defmodule Pet do
    defmodule Cat do
      defstruct [:name, :profiles, :owner]
    end

    defmodule Dog do
      defstruct [:name, :profiles, :owner]
    end

    defmodule Fish do
      defstruct [:name, :profiles, :owner]
    end

    def pets(_, _, _) do
      {:ok, []}
    end

    def add(
          _,
          %{pet: %{cat: %{name: name, profiles: profiles, owner: owner}}},
          _
        ) do
      {:ok, owner} = AbsintheOneOfTest.Owner.add(owner)
      {:ok, %Cat{name: name, profiles: build_profiles(profiles), owner: owner}}
    end

    def add(
          _,
          %{pet: %{dog: %{name: name, profiles: profiles, owner: owner}}},
          _
        ) do
      {:ok, owner} = AbsintheOneOfTest.Owner.add(owner)
      {:ok, %Dog{name: name, profiles: build_profiles(profiles), owner: owner}}
    end

    def add(
          _,
          %{pet: %{fish: %{name: name, profiles: profiles, owner: owner}}},
          _
        ) do
      {:ok, owner} = AbsintheOneOfTest.Owner.add(owner)
      {:ok, %Fish{name: name, profiles: build_profiles(profiles), owner: owner}}
    end

    defp build_profiles(profiles) do
      Enum.map(profiles, fn profile ->
        [{key, value}] = Map.to_list(profile)
        %{key: "#{key}", value: "#{value}"}
      end)
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

    union(:owner) do
      types([:person, :organization])

      resolve_type(fn
        %AbsintheOneOfTest.Owner.Person{}, _ -> :person
        %AbsintheOneOfTest.Owner.Organization{}, _ -> :organization
      end)
    end

    object(:person) do
      field(:name, non_null(:string))
      field(:age, non_null(:integer))
    end

    object(:organization) do
      field(:name, non_null(:string))
      field(:registration_number, non_null(:integer))
    end

    object(:profile) do
      field(:key, non_null(:string))
      field(:value, non_null(:string))
    end

    object(:cat) do
      field(:name, non_null(:string))
      field(:profiles, non_null(list_of(:profile)))
      field(:owner, non_null(:owner))
    end

    object(:dog) do
      field(:name, non_null(:string))
      field(:profiles, non_null(list_of(:profile)))
      field(:owner, non_null(:owner))
    end

    object(:fish) do
      field(:name, non_null(:string))
      field(:profiles, non_null(list_of(:profile)))
      field(:owner, non_null(:owner))
    end

    input_object(:owner_input) do
      directive(:one_of)
      field(:person, :person_input)
      field(:organization, :organization_input)
    end

    input_object(:person_input) do
      field(:name, non_null(:string))
      field(:age, non_null(:integer))
    end

    input_object(:organization_input) do
      field(:name, non_null(:string))
      field(:registration_number, non_null(:integer))
    end

    input_object(:profile_input) do
      directive(:one_of)
      field(:number_of_lives, :integer)
      field(:wags_tail, :boolean)
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
      field(:profiles, non_null(list_of(:profile_input)))
      field(:owner, non_null(:owner_input))
    end

    input_object(:dog_input) do
      field(:name, non_null(:string))
      field(:profiles, non_null(list_of(:profile_input)))
      field(:owner, non_null(:owner_input))
    end

    input_object(:fish_input) do
      field(:name, non_null(:string))
      field(:profiles, non_null(list_of(:profile_input)))
      field(:owner, non_null(:owner_input))
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
        profiles {
          key
          value
        }
        owner {
          ... on Person {
            name
            age
          }
          ... on Organization {
            name
            registrationNumber
          }
          __typename
        }
      }
      ... on Dog {
        name
        profiles {
          key
          value
        }
        owner {
          ... on Person {
            name
            age
          }
          ... on Organization {
            name
            registrationNumber
          }
          __typename
        }
      }
      ... on Fish {
        name
        profiles {
          key
          value
        }
        owner {
          ... on Person {
            name
            age
          }
          ... on Organization {
            name
            registrationNumber
          }
          __typename
        }
      }
      __typename
    }
  }
  """

  test "one_of valid input" do
    variables = %{
      "pet" => %{
        "cat" => %{
          "name" => "Whiskers",
          "profiles" => [%{"numberOfLives" => 9}],
          "owner" => %{
            "person" => %{
              "name" => "Alice",
              "age" => 30
            }
          }
        }
      }
    }

    assert %{
             "data" => %{
               "add" => %{
                 "__typename" => "Cat",
                 "name" => "Whiskers",
                 "profiles" => [%{"key" => "number_of_lives", "value" => "9"}],
                 "owner" => %{
                   "__typename" => "Person",
                   "name" => "Alice",
                   "age" => 30
                 }
               }
             }
           } ==
             conn(:post, "/", %{query: @mutation, variables: variables})
             |> call()
             |> json_response(200)
  end

  test "one_of object invalid input" do
    variables = %{
      "pet" => %{
        "cat" => %{
          "name" => "Whiskers",
          "profiles" => [%{"numberOfLives" => 9}],
          "owner" => %{
            "person" => %{
              "name" => "Alice",
              "age" => 30
            }
          }
        },
        "dog" => %{
          "name" => "Odie",
          "profiles" => [%{"wagsTail" => true}],
          "owner" => %{
            "person" => %{
              "name" => "Alice",
              "age" => 30
            }
          }
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

  test "one_of nested object invalid input" do
    variables = %{
      "pet" => %{
        "cat" => %{
          "name" => "Whiskers",
          "profiles" => [%{"numberOfLives" => 9}],
          "owner" => %{
            "person" => %{
              "name" => "Alice",
              "age" => 30
            },
            "organization" => %{
              "name" => "Acme Corp",
              "registrationNumber" => 12_345
            }
          }
        }
      }
    }

    assert %{
             "errors" => [
               %{
                 "message" =>
                   "OneOf Object \"owner\" must have exactly one non-null field but got 2."
               }
             ]
           } ==
             conn(:post, "/", %{query: @mutation, variables: variables})
             |> call()
             |> json_response(200)
  end

  test "one_of nested list object invalid input" do
    variables = %{
      "pet" => %{
        "cat" => %{
          "name" => "Whiskers",
          "profiles" => [%{"numberOfLives" => 9, "wagsTail" => true}],
          "owner" => %{
            "person" => %{
              "name" => "Alice",
              "age" => 30
            }
          }
        }
      }
    }

    assert %{
             "errors" => [
               %{
                 "message" =>
                   "OneOf Object \"profiles\" must have exactly one non-null field but got 2."
               }
             ]
           } ==
             conn(:post, "/", %{query: @mutation, variables: variables})
             |> call()
             |> json_response(200)
  end
end
