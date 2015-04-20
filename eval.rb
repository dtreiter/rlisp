class Environment
  attr_accessor :names # names which are defined in this env (ie. variables, functions)
  attr_accessor :parent # parent environment

  def initialize(parent)
    @names = Hash.new
    @parent = parent
  end

  def find(name)
    if @names.has_key? name
      return @names[name]
    elsif @parent == nil
      # TODO This always fails at the end of a program
      return nil
      #raise "Unknown symbol: " + name.to_s
    else
      @parent.find name
    end
  end
end

# Initialize the global env
$global_env = Environment.new nil
$global_env.names = {
  "+" => lambda {|args|
    val = 0
    args.each do |arg|
      val += arg
    end
    val
  },
  "-" => lambda {|args|
    val = args[0]
    args[1..args.length].each do |arg|
      val -= arg
    end
    val
  },
  "=" => lambda {|args|
    # TODO Verify args.length
    args[0] == args[1]
  },
  "<" => lambda {|args|
    args[0] < args[1]
  },
  ">" => lambda {|args|
    args[0] > args[1]
  },
  "print" => lambda {|a| puts a}
}

class ASTnode
  attr_accessor :parent
  attr_accessor :children
  attr_accessor :content

  def initialize(parent, content)
    @parent = parent
    @children = Array.new
    @content = content
  end

  def has_children?
    @children.length > 0
  end

  def add_child(child)
    @children.push child
  end

  def first_child
    @children.first
  end

  def print_children
    if @content.is_a? Integer
      puts "int:" + @content.to_s
    else
      puts @content
    end
    if @children.any?
      @children.each do |child|
        child.print_children
      end
    end
  end
end

class Interpreter
  def initialize(text)
    @text = text
    @rootnode = ASTnode.new(nil, nil)
  end

  def tokenize
    @text.gsub!(/^;.*$/, "") # Remove comments
    @text.gsub!("(", " ( ")
    @text.gsub!(")", " ) ")
    @tokens = @text.split(" ")

    # Check the type of each token.
    # NOTE: Currently only support Integers
    @tokens.collect! do |token|
      begin
        token = Integer(token)
      rescue ArgumentError
        token
      end
    end
  end

  def parse
    curnode = @rootnode
    list_head = false
    @tokens.each do |value|
      if value == "("
        list_head = true
      elsif value == ")"
        curnode = curnode.parent
      else
        next_node = ASTnode.new(curnode, value)
        curnode.add_child next_node
        if list_head
          curnode = next_node
          list_head = false
        end
      end
    end
    @rootnode = @rootnode
  end

  def eval(curnode=@rootnode, env=$global_env)
    # Evaluate children if necessary
    args = Array.new
    curnode.children.each do |node|
      if node.has_children?
        args.push eval(node, env)
      else
        args.push node.content
      end
    end

    if curnode.content == "define"
      $global_env.names[args[0]] = args[1]
    else
      value = env.find curnode.content
      if value.is_a? Proc
        args.collect! do |arg|
          if arg.is_a? Integer
            arg
          else
            # Lookup symbol
            env.find arg
          end
        end
        ret_value = value.call(args)
      end
    end

    if curnode.parent == nil # TODO This is ugly? The program returns an array
      args
    else
      ret_value
    end
  end

  def print_ast
    @rootnode.print_children
  end
end

def test
  code = File.read("./test.rlisp") # TODO Maybe don't read the entire file at once?
  interpreter = Interpreter.new(code)
  interpreter.tokenize
  interpreter.parse
  #interpreter.print_ast
  interpreter.eval
end

test
