class GraphQL::Token
  START_OF_FILE = new

  module Kinds
    SOF       = :SOF
    EOF       = :EOF
    BANG      = :"!"
    DOLLAR    = :"$"
    PAREN_L   = :"("
    PAREN_R   = :")"
    SPREAD    = :"..."
    COLON     = :":"
    EQUALS    = :"="
    AT        = :"@"
    BRACKET_L = :"["
    BRACKET_R = :"]"
    BRACE_L   = :"{"
    PIPE      = :"|"
    BRACE_R   = :"}"
    NAME      = :Name
    INT       = :Int
    FLOAT     = :Float
    STRING    = :String
    COMMENT   = :Comment
  end

  getter kind : Symbol
  getter start : Int32
  getter end : Int32
  getter line : Int32
  getter column : Int32
  getter value : String?
  getter prev : Token?
  getter next : Token?
  getter value : String?

  def initialize(@kind = SOF, @start = 0, @end = 0, @line = 0, @column = 0, @prev = nil, @value = nil)
  end
end
