# Support for dumping database functions.
module PgSaurus::SchemaDumper::FunctionMethods

  # :nodoc
  def tables_with_functions(stream)
    tables_without_functions(stream)

    dump_functions stream

    stream
  end

  # Writes out a command to create each detected function.
  def dump_functions(stream)
    @connection.functions.each do |function|
      definition = function.definition.split("\n").map{|line| "    #{line}" }.join("\n")
      name = "#{function.name}(#{function.arguments.join(', ')})"
      statement = "  create_function '#{name}', '#{function.returning}', <<-FUNCTION_DEFINITION.gsub(/^[\s]{4}/, '')"

      options = {}
      options[:schema] = function.schema
      options[:replace] = false if function.replace == false
      options[:language] = function.language if function.language != 'plpgsql'
      if options.keys.size > 0
        statement << ", #{options.inspect}"
      end

      statement << "\n#{definition}"
      statement << "\n  FUNCTION_DEFINITION\n\n"

      stream.puts statement
    end
  end

end
