# Starting Server
HTTP::Server.new("127.0.0.1", 8080, [
  HTTP::ErrorHandler.new,
  HTTP::LogHandler.new,
  HTTP::DeflateHandler.new,
  GraphQLHandler(schema: Schema, graphiql: true),
]).listen

class Schema < GraphQL::Schema
  query QueryType
  mutation MutationType
  subscription SubscriptionType
end

class QueryType < GraphQL::Object do
  field Node.field
  interfaces [Node.interface]
end

class Node < GraphQL::NodeDefinition
  resolve_type do |object|
    object.class.name.split("::").last
  end
  
  resolve_object do |gid, args, context|
    type_name, id = from_global_id(gid)
    model = case type
            {{ for model in Model.subclasses }}
            when {{ model.stringify.split("::").last }}
              {{ model }}
            {{ end }
            else
              raise "type not found: #{type_name}"
            end
    model.find_by(id: id)
  end
end

class User < GraphQLObject
  field 
end
