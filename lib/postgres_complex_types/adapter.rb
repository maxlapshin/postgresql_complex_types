module PostgresComplexTypes
  module Adapter
    def user_types(name = nil)
      schemas = schema_search_path.split(/,/).map { |p| quote(p) }.join(',')
      query(<<-SQL, name).map { |row| row[0] }
        SELECT t.typname FROM pg_type t
	LEFT JOIN pg_namespace n ON (n.oid = t.typnamespace) 
	WHERE nspname in (#{schemas}) AND
	      (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)
	      AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
      SQL
    end

    def native_database_types
      NATIVE_DATABASE_TYPES.merge(user_types.inject({}) do |list, name|
        list[name.underscore.to_sym] = {:name => name}
	list
      end)
    end
  end
end

