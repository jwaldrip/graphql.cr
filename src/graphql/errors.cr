require "./source"

module GraphQL
  class SyntaxError < Exception
    @source : Source?
    @position : Int32?

    def initialize(@source : Source, @position : Int32, message : String)
      initialize(message)
    end

    def initialize(source : Source, position : Int32, char : Char)
      message = if char == '\''
                  "Unexpected single quote character ('), did you mean to use a double quote (\")?"
                else
                  "Cannot parse the unexpected character #{char}."
                end
      initialize(source, position, message)
    end
  end
end
