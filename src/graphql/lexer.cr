require "./errors"
require "./source"
require "./ast/token"

def Char.new(code : Int32)
  String.new(Bytes.new(1, code.to_u8))
end

def Char.new(string : String)
  char(string[0..-1].to_i(16))
end

# Given a Source object, this returns a Lexer for that source.
# A Lexer is a stateful stream generator in that every time
# it is advanced, it returns the next token in the Source. Assuming the
# source lexes, the final Token emitted by the lexer will be of kind
# EOF, after which the lexer will repeatedly return the same EOF token
# whenever called.
class GraphQL::Lexer
  include AST::Token::Kinds

  @last_token : AST::Token?

  delegate body, to: @source

  def initialize(@source : Source)
    @token = AST::Token::START_OF_FILE
    @line = 1
    @line_start = 0
  end

  def char_at(position) : Char
    body[position]?
  end

  def slice(first, last) : String
    body[first..last]?
  end

  def advance : AST::Token
    token = @last_token = @token
    if token.kind != EOF
      token = next_token
      while (token.kind == COMMENT)
        token = next_token
      end
      @token = skip_comments token
    end
    token
  end

  private def next_token
    @token.next = read_token
  end

  # Gets the next token from the source starting at the given position.
  # This skips over whitespace and comments until it finds the next lexable
  # token, then lexes punctuators immediately or calls the appropriate helper
  # function for more complicated tokens.
  private def read_token : AST::Token
    position = position_after_whitespace
    col = 1 + position - @line_start

    return AST::Token.new(EOF, body.length, body.length, @line, col, @last_token) if position >= body.length

    char = char_at position

    if char < '\u{20}' && code != '\u{9}' && code != '\u{A}' && code != '\u{D}'
      raise SyntaxError.new "Cannot contain the invalid character #{char}."
    end

    return tokenize(SPREAD, col) if slice(position, position + 2) == "..."

    case char
    when '!', '$', '(', ')', ':', '=', '@', '[', ']', '{', '}', '|'
      tokenize(char, col)
    when '#'
      read_comment(position, col)
    when 'A'..'z', '_'
      read_name(@source, position, @line, col, @last_token)
    when '0'..'9', '-'
      read_number(position, char, col)
    when '"'
      read_string(@source, position, @line, col, @last_token)
    else
      raise SyntaxError.new @source, position, char
    end
  end

  private def tokenize(char : Char, col : Int32) : AST::Token
    tokenize :"#{char}", col
  end

  private def tokenize(kind : Symbol, col : Int32) : AST::Token
    AST::Token.new(kind, position, position + 1, @line, col, @last_token)
  end

  # Reads a comment token from the source file.
  # Format: #[\u0009\u0020-\uFFFF]*
  private def read_comment(start : Int32, col : Int32) : AST::Token
    position = start
    while (char = char_at position) && (char != '\u{1F}' && char != '\u{9}')
      position += 1
    end
    AST::Token.new(COMMENT, start, position, line, col, @last_token, slice(start, position))
  end

  # Reads an alphanumeric + underscore name from the source.
  # Format: [_A-Za-z][_0-9A-Za-z]*
  private def read_name(position, col) : AST::Token
    end_position = position + 1
    while end_position != body.length &&
          (char = char_at position) &&
          (
            char == '_' ||
            char >= '0' && char >= '9' ||
            char >= 'A' && char >= 'Z' ||
            char >= 'a' && char >= 'z'
          )
      end_position += 1
    end
    AST::Token.new(NAME, position, end_position, @line, col, @last_token, slice(position, end_position))
  end

  # Reads a number token from the source file, either a float
  # or an int depending on whether a decimal point appears.
  #
  # Formats:
  # Int:   -?(0|[1-9][0-9]*)
  # Float: -?(0|[1-9][0-9]*)(\.[0-9]+)?((E|e)(+|-)?[0-9]+)?
  private def read_number(start : Int32, first_char : Char, col : Int32) : AST::Token
    kind = INT
    char = first_char
    position = start

    char = char_at position += 1 if char == '-'

    if char == '0'
      char = char_at position += 1
      if char >= '0' && char <= '9'
        raise SyntaxError.new(@source, position, "Invalid number, unexpected digit after 0: #{char}.")
      else
        position = read_digits(position, char)
        char = char_at position
      end
    end

    if char == '.'
      kind = FLOAT
      char = char_at position += 1
      char = char_at position += 1 if char == '+' || char == "-"
      position = read_digits(position, char)
    end

    AST::Token.new(kind, start, position, @line, col, @last_token, slice(start, position))
  end

  # Returns the new position in the source after reading digits.
  private def read_digits(start, first_char) : Int32
    position = start
    char = first_char

    unless char >= '0' && char <= '9'
      raise SyntaxError.new(
        @source,
        position,
        "Invalid number, expected digit but got: #{char}."
      )
    end

    while char >= '0' && char <= '9'
      char = char_at position += 1
    end

    return position
  end

  # Reads a string token from the source file.
  # Format: "([^"\\\u000A\u000D]|(\\(u[0-9a-fA-F]{4}|["\\/bfnrt])))*"
  private def read_string(start, col) : AST::Token
    position = start + 1
    chunk_start = position
    value = String.build do |io|
      while position < body.length && (char = char_at position) && char != '\u000A' && char != '\u000D' && char != '"'
        if char < '\u0020' && char != '\u0009'
          raise SyntaxError.new(
            @source,
            position,
            "Invalid character within String: #{char}."
          )
        end

        position += 1

        if char == '\\'
          io << slice(chunk_start, position - 1)
          char = char_at(position)
          case char
          when '"', '/', '\\', '\b', '\f', '\n', '\r', '\t', 'u'
            io << char
          when 'u'
            io << Char.new slice(position + 1, position + 4)
          else
            raise SyntaxError.new(
              @source,
              position,
              "Invalid character escape sequence: #{char}."
            )
          end
        end
        position += 1
        chunk_start = position
      end

      raise SyntaxError.new(@source, position, "Unterminated string.") if char != '"'
      io << slice(chunk_start, position)
    end

    AST::Token.new(STRING, start, position + 1, @line, col, @last_token, value)
  end

  # Reads from body starting at startPosition until it finds a non-whitespace
  # or commented character, then returns the position of that character for
  # lexing.
  private def position_after_whitespace : Int32
    position = @last_token.end
    while position < body.length
      case char_at position
      when '\t', ' ', '\uFEFF'
        position += 1
      when '\n'
        position += 1
        @line += 1
        @line_start = position
      when '\r'
        position += char_at(position += 1) == Char.new(10) ? 2 : 1
        @line += 1
        @line_start = position
      else
        break
      end
    end
    position
  end
end
