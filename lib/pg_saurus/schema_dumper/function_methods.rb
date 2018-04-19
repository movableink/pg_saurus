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
      next unless function.language == 'plpgsql'
      definition = function.definition.split("\n").map{|line| "    #{line}" }.join("\n")
      name = "#{function.name}(#{function.arguments.join(', ')})"
      statement = "  create_function '#{name}', '#{function.returning}', <<-FUNCTION_DEFINITION.gsub(/^[\s]{4}/, '')"

      statement << ", schema: '#{function.schema}'" if function.schema
      statement << ", replace: #{function.replace}" if function.replace == false

      statement << "\n#{definition}"
      statement << "\n  FUNCTION_DEFINITION\n\n"

      stream.puts statement
    end
  end

end
