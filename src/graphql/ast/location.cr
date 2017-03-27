class GraphQL::AST::Location
  property start : UInt64
  property end : UInt64
  property start_token : Token
  property end_token : Token
  property source : Source
end
