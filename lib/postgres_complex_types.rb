begin
  require 'inline'
  require 'postgres_complex_types/fast_postgres_extractor'
  PostgresComplexTypes::PostgresExtractor = PostgresComplexTypes::FastPostgresExtractor
rescue Exception => e
  puts "#{e.inspect}\n#{e.backtrace.join("\n")}"
  require 'postgres_complex_types/postgres_extractor'
end

require 'postgres_complex_types/column'
require 'postgres_complex_types/adapter'
require 'postgres_complex_types/schema_statements'
require 'postgres_complex_types/dumper'

module PostgresComplexTypes
end

