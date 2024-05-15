[![CI](https://github.com/rudebono/absinthe_one_of/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/rudebono/absinthe_one_of/actions/workflows/ci.yaml)

# Absinthe one_of

Support an Input Union Type System Directive in Absinthe.

## Inspiration

This package was inspired by an article written by [Maarten Van Vliet](https://github.com/maartenvanvliet).

You can read the original article [Creating an Input Union Type System Directive in Absinthe](https://maartenvanvliet.nl/2022/04/28/absinthe_input_union/).

## Key Improvements

- **Nested Objects**: Allows for `one_of` validation within nested object structures.
- **Nested List Objects**: Supports `one_of` validation within nested lists of objects.

## Installation

Add `:absinthe_one_of` to your list of dependencies in `mix.exs`:

```elixir
def deps() do
  [
    {:absinthe_one_of, "~> 1.1"}
  ]
end
```

## Usage

### Step 1: Define Schema

Create a schema module and define your types, including the `@prototype_schema AbsintheOneOf.Directive`:

```elixir
defmodule YourWebApp.Schema do
  use Absinthe.Schema

  @prototype_schema AbsintheOneOf.Directive

  query do
    ...
  end

  mutation do
    ...
  end

  subscription do
    ...
  end

  ...

  input_object(:one_of_input) do
    directive(:one_of)
    field(:a, :a_input)
    field(:b, :b_input)
  end

  input_object(:a_input) do
    ...
  end

  input_object(:b_input) do
    ...
  end
end
```

### Step 2: Setup Absinthe Pipeline

Configure the Absinthe pipeline to include the `absinthe_one_of` phase:

```elixir
defmodule YourWebApp.Endpoint do
  use YourWebApp, :router

  ...

  def pipeline(config, pipeline_opts) do
    config.schema_mod
    |> Absinthe.Pipeline.for_document(pipeline_opts)
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Validation.OnlyOneSubscription,
      AbsintheOneOf.Phase
    )
  end
end
```

### Step 3: Testing

To write tests for your implementation, you can refer to the example tests provided in `test/absinthe_one_of_test.exs`. These tests demonstrate how to validate the functionality of the one_of directive and ensure that only one field is non-null among several options.

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
