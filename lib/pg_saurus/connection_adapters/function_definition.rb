module PgSaurus::ConnectionAdapters
  # Struct definition for a DB function.
  class FunctionDefinition < Struct.new( :name,
                                         :returning,
                                         :definition,
                                         :function_type,
                                         :language,
                                         :arguments,
                                         :replace,
                                         :schema,
                                         :oid )
  end
end
