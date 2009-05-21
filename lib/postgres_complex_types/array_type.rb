module PostgresComplexTypes
  module TypeMap
    def self.register_type(type, name)
      @type_map ||= {}
      @type_map[type] ||= {}
      @type_map[type][:primitive] = name
    end
    
    def self.type_map
      @type_map || {}
    end
    
    def type_map
      super.merge(PostgresComplexTypes::TypeMap.type_map)
    end
  end
end

module DataMapper
  module Types
    class PGArray < DataMapper::Type
      primitive String
      def self.inner_property=(prop)
        @inner_property = prop
      end
      def self.inner_property
        @inner_property
      end

      def self.load(value, property)
        return unless value
        puts "Loading: #{value.inspect}"
        PostgresComplexTypes::PostgresExtractor.new(value).result.map do |part|
          inner_property.typecast(part)
        end
      end

      def self.dump(values, property)
        puts "Asked to dump #{values.inspect}"
        return values if values.is_a?(String)
        return unless values
        "{" + values.map do |value|
          val = inner_property.typecast(value)
          return unless val
          if val.to_s.index('"')
            val = '"' + val.gsub('"', '""') + '"'
          end
          val
        end.join(",") + "}"
      end

      def self.typecast(values, property)
        v = dump(values, property)
        puts "TC: #{values.inspect} -> #{v.inspect}"
        v
      end
    end # class PGArray
  end # module Types


  module Model
    def PGArray(klass, name)
      c = Class.new(::DataMapper::Types::PGArray)
      c.primitive String
      if klass.is_a?(Symbol)
        fields = repository(:default).adapter.query("select attname from pg_attribute where attrelid = '#{klass}'::regclass").map(&:to_sym)
        record = const_set(klass.to_s.classify, Struct.new(*fields))
        record.send(:include, PostgresComplexTypes::StructDecoder)
        c.inner_property = record
        PostgresComplexTypes::TypeMap.register_type(c, "#{klass}[]")
      else
        c.primitive klass
        c.inner_property = Property.new(self, name, klass, {})
        PostgresComplexTypes::TypeMap.register_type(c, repository(:default).adapter.class.type_map[klass][:primitive]+"[]")
      end
      c
    end
  end # module Model
  
  module Adapters
    class << PostgresAdapter
      include PostgresComplexTypes::TypeMap
    end
  end
end # module DataMapper

