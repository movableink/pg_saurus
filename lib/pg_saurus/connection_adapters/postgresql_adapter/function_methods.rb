# Methods to extend {ActiveRecord::ConnectionAdapters::PostgreSQLAdapter}
# to support database functions.
module PgSaurus::ConnectionAdapters::PostgreSQLAdapter::FunctionMethods

  # Return +true+.
  def supports_functions?
    true
  end

  # Return a list of defined DB functions. Ignore function definitions that can't be parsed.
  def functions
    res = select_all <<-SQL
      SELECT n.nspname AS "Schema",
        p.proname AS "Name",
        l.lanname AS "Language",
        p.prosrc AS "Source",
        pg_get_functiondef(p.oid) ILIKE '%CREATE OR REPLACE%' AS "Replace",
        pg_catalog.pg_get_function_result(p.oid) AS "Returning",
        pg_get_function_arguments(p.oid) AS "Arguments",
       CASE
        WHEN p.proiswindow                                           THEN 'window'
        WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger'
        ELSE 'normal'
       END   AS "Type",
       p.oid AS "Oid"
      FROM pg_catalog.pg_proc p
           LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
           LEFT JOIN pg_depend d ON d.objid = p.oid AND d.deptype = 'e'
           LEFT JOIN pg_catalog.pg_language l ON p.prolang = l.oid
      WHERE pg_catalog.pg_function_is_visible(p.oid)
            AND n.nspname <> 'pg_catalog'
            AND n.nspname <> 'information_schema'
            AND p.proisagg <> TRUE
            AND d.objid IS NULL
      ORDER BY 1, 2, 3, 4;
    SQL
    res.map do |row|
      returning     = row['Returning']
      function_type = row['Type']
      name          = row['Name']
      definition    = row['Source']
      language      = row['Language']
      oid           = row['Oid']
      or_replace    = row['Replace'] != 'f'
      schema        = row['Schema']

      # in format ['arg_a character varying', 'arg_b integer', ...]
      arguments = row['Arguments'].split(", ")

      next unless definition

      ::PgSaurus::ConnectionAdapters::FunctionDefinition.new(name,
                                                             returning,
                                                             definition.strip,
                                                             function_type,
                                                             language,
                                                             arguments,
                                                             or_replace,
                                                             schema,
                                                             oid)
    end.compact
  end

  # Create a new database function.
  def create_function(function_name, returning, definition, options = {})
    function_name = full_function_name(function_name, options)
    language      = options[:language] || 'plpgsql'

    create = 'CREATE'
    create << ' OR REPLACE' unless options[:replace] == false
    create << ' FUNCTION'

    sql = <<-SQL.gsub(/^[ ]{6}/, "")
      #{create} #{function_name}
        RETURNS #{returning}
        LANGUAGE #{language}
      AS $function$
      #{definition.strip}
      $function$
    SQL

    execute(sql)
  end

  # Drop the given database function.
  def drop_function(function_name, options = {})
    function_name = full_function_name(function_name, options)

    execute "DROP FUNCTION #{function_name}"
  end

  # Write out the fully qualified function name if the :schema option is passed.
  def full_function_name(function_name, options)
    schema        = options[:schema]
    function_name = %Q{"#{schema}".#{function_name}} if schema
    function_name
  end
  private :full_function_name
end
