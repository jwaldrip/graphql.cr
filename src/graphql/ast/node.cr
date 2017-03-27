abstract class GraphQL::AST::Node
  property loc : Location?

  def kind
    self.class.name.chomp("Node")
  end
end
