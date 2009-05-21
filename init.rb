require 'postgres_complex_types'

if defined?(ActiveRecord)
  require 'postgres_complex_types/column'
  require 'postgres_complex_types/adapter'
  require 'postgres_complex_types/schema_statements'
  require 'postgres_complex_types/dumper'

  ::ActiveRecord::ConnectionAdapters::PostgreSQLColumn.class_eval {include PostgresComplexTypes::Column}
  ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval {include PostgresComplexTypes::Adapter}
  ::ActiveRecord::SchemaDumper.class_eval {include PostgresComplexTypes::Dumper}
end

if defined?(::DataMapper)
  Object.require 'postgres_complex_types/array_type'
end
