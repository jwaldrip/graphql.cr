require "../token"
require "../source"

class GraphQL::AST::Location
  property position_start : Int32
  property position_end : Int32
  property start_token : Token
  property end_token : Token
  property source : Source
end
