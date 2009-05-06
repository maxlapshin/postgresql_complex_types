module PostgresComplexTypes
module Column
  
  def sql_array
    @sql_array
  end

  def initialize(name, default, sql_type = nil, null = true)
    if sql_type =~ /([^\[]+)\[\]/
      @sql_array = true
      sql_type = $1
      if !simplified_type(sql_type)
        @constructor = constructor(sql_type)
      end
    end
    super
    if @constructor
      @type = sql_type.underscore.to_sym
    end
  end

  def constructor(record_type)
    record_name = record_type.classify
    klass = begin
      record_name.constantize
    rescue NameError
      fields = ActiveRecord::Base.connection.select_values("select attname from pg_attribute where attrelid = '#{record_type}'::regclass").map(&:to_sym)
      record = Column.const_set(record_name, Struct.new(*fields))
      record.send(:include, PostgresComplexTypes::StructDecoder)
      record
    end
  end

  def type_cast_array(value)
    return unless value
    PostgresComplexTypes::PostgresExtractor.new(value).result.map do |part|
      if @constructor
        @constructor.unmarshall(part)
      elsif type
        type_cast(part, false)
      else
        part
      end
    end
  end

  def type_cast(value, array_check = true)
    return type_cast_array(value) if @sql_array && array_check
    super(value)
  end
  
  def type_cast_code(var_name)
    return "self.class.columns.find{|c| c.name == #{self.name.inspect} }.type_cast_array(#{var_name})" if @sql_array
    super(var_name)
  end
end
end

