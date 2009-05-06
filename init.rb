require 'postgres_complex_types'

::ActiveRecord::ConnectionAdapters::PostgreSQLColumn.class_eval {include PostgresComplexTypes::Column}
::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval {include PostgresComplexTypes::Adapter}
::ActiveRecord::SchemaDumper.class_eval {include PostgresComplexTypes::Dumper}

