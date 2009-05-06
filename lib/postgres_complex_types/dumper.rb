module PostgresComplexTypes
  module Dumper
    def self.included(base)
      base.instance_eval do
        alias_method_chain :tables, :user_types
      end
    end

    def tables_with_user_types(stream)
      @connection.user_types.sort.each do |type|
        next if ['schema_migrations', ignore_tables].flatten.any? do |ignored|
          case ignored
          when String; type == ignored
          when Regexp; type =~ ignored
          else
            raise StandardError, "ActiveRecord::SchemaDumper.ignore_tables accepts an array of String and / or Regexp values. {ignored.inspec}"
          end
        end 
	@types[type.to_sym] = {:name => type, :limit => nil}
        user_type(type, stream)
      end

      tables_without_user_types(stream)
    end

    def user_type(type, stream)
      columns = @connection.columns(type)
      begin
        tbl = StringIO.new

        tbl.puts "  create_type #{type.inspect} do |t|"

        column_specs = columns.map do |column|
          raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
          spec = {}
          spec[:name]      = column.name.inspect
          spec[:type]      = column.type.to_s
          spec[:limit]     = column.limit.inspect if !column.sql_array && column.limit != @types[column.type][:limit] && column.type != :decimal
          spec[:array]     = "true" if column.sql_array
          spec[:precision] = column.precision.inspect if !column.precision.nil?
          spec[:scale]     = column.scale.inspect if !column.scale.nil?
          spec[:null]      = 'false' if !column.null
          spec[:default]   = default_string(column.default) if column.has_default?
          (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
          spec
        end.compact

        # find all migration keys used in this type
        keys = [:name, :limit, :precision, :scale, :default, :null, :array] & column_specs.map(&:keys).flatten

        # figure out the lengths for each column based on above keys
        lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

        # the string we're going to sprintf our values against, with standardized column widths
        format_string = lengths.map{ |len| "%-#{len}s" }

        # find the max length for the 'type' column, which is special
        type_length = column_specs.map{ |column| column[:type].length }.max

        # add column type definition to our format string
        format_string.unshift "    t.%-#{type_length}s "

        format_string *= ''

        column_specs.each do |colspec|
          values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
          values.unshift colspec[:type]
          tbl.print((format_string % values).gsub(/,\s*$/, ''))
          tbl.puts
        end

        tbl.puts "  end"
        tbl.puts
          
        tbl.rewind
        stream.print tbl.read
      rescue => e
        stream.puts "# Could not dump type #{type.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        stream.puts
      end
    end
  end
end
