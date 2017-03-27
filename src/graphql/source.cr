# A representation of source input to GraphQL. The name is optional,
# but is mostly useful for clients who store GraphQL documents in
# source files; for example, if the GraphQL input is in a file Foo.graphql,
# it might be useful for name to be "Foo.graphql"
class GraphQL::Source
  def initialize(@body : String, @name : String? = "GraphQL")
  end
end
