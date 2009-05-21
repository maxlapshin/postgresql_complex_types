begin
  gem 'RubyInline'
  require 'inline'
  require 'postgres_complex_types/fast_postgres_extractor'
  PostgresComplexTypes::PostgresExtractor = PostgresComplexTypes::FastPostgresExtractor
rescue LoadError => e
  puts "#{e.inspect}\n#{e.backtrace.join("\n")}"
  require 'postgres_complex_types/postgres_extractor'
end


module PostgresComplexTypes
end

