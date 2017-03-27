class Query < GraphQL::Schema
  query Root
  mutation Mutation
end

class MyType < GraphQL::Object
  name MyTypeName
  description "some awesome description"

  field node : Node
  field name, {
    type: String,
  }
  field id : ID
  field type : String
  field body : String
  field comments : Array(String)
end

class MyType
  GraphQL.mapping("MyType", {
    node:     Node,
    name:     String?,
    type:     String,
    body:     String,
    comments: Array(Comment),
  })
end
