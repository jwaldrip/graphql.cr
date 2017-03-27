class GraphQL::AST::DocumentNode < GraphQL::AST::Node
  property definitions : Array(DefinitionNode)
end
