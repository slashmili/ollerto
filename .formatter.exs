locals_without_parens = [
  field: 2,
  field: 3,
  belongs_to: 2,
  middleware: 1,
  middleware: 2,
  description: 1,
  get: 3,
  pipe_through: 1,
  forward: 2,
  forward: 3,
  plug: 2,
  plug: 1,
  resolve: 3,
  input_object: 2,
  import_types: 1,
  arg: 2,
  resolve: 1
]

[
  inputs: [
    "lib/**/*.{ex,exs}",
    "test/**/*.{ex,exs}",
    "mix.exs"
  ],
  locals_without_parens: locals_without_parens
]
