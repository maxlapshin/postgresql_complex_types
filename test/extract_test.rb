require File.dirname(__FILE__)+"/test_helper"

class FinderTest < Test::Unit::TestCase
  # include RubyProf::Test
  
  def test_parse_array
    assert_equal ["1","2","3","4"], PostgresExtractor.new("{1,2,3,4}").result
  end

  def test_parse_array_with_nil
    assert_equal ["1",nil,"NULL","4"], PostgresExtractor.new("{1,NULL,\"NULL\",4}").result
  end

  def test_fast_parse_array_with_nil
    assert_equal ["1",nil,"NULL","4"], FastPostgresExtractor.new("{1,NULL,\"NULL\",4}").result
  end
 
  def test_fast_parse_array
    assert_equal ["1","2","3","4"], FastPostgresExtractor.new("{1,2,3,4}").result
  end
  
  def test_parse_string_array
    s = %q({"foo\\"",bar,"foo,\\"'",bar})
    assert_equal ['foo"','bar','foo,"\'','bar'], PostgresExtractor.new(s).result
  end
  
  def test_fast_parse_string_array
    s = %q({"foo\\"",bar,"foo,\\"'",bar})
    assert_equal ['foo"','bar','foo,"\'','bar'], FastPostgresExtractor.new(s).result
  end
  
  def test_parse_composite_type
    assert_equal ["1","2","3","4"], PostgresExtractor.new("(1,2,3,4)").result
  end

  def test_parse_composite_type_with_nil
    assert_equal ["1",nil,"3","4",nil], PostgresExtractor.new("(1,,3,4,)").result
  end
  
  def test_parse_composite_type_with_two_nulls
    assert_equal [nil,nil,"1"], PostgresExtractor.new("(,,1)").result
  end

  def test_fast_parse_composite_type_with_two_nulls
    assert_equal [nil,nil,"1"], FastPostgresExtractor.new("(,,1)").result
  end

  def test_parse_composite_type_with_four_nulls
    assert_equal [nil,nil,"1",nil,nil], PostgresExtractor.new("(,,1,,)").result
  end

  def test_fast_parse_composite_type_with_four_nulls
    assert_equal [nil,nil,"1",nil,nil], FastPostgresExtractor.new("(,,1,,)").result
  end
  
  def test_fast_parse_composite_type_with_nil
    assert_equal ["1",nil,"3","4",nil], FastPostgresExtractor.new("(1,,3,4,)").result
  end
  
  def test_fast_parse_composite_type
    assert_equal ["1","2","3","4"], FastPostgresExtractor.new("(1,2,3,4)").result
  end
  
  def test_array_of_composite
    s = %q({"(\"foo\"\"\",bar)","(\"foo,\"\"'\",bar)"})
    assert_equal [['foo"','bar'],['foo,"\'','bar']], PostgresExtractor.new(s).result
  end
  
  def test_fast_array_of_composite
    s = %q({"(\"foo\"\"\",bar)","(\"foo,\"\"'\",bar)"})
    assert_equal [['foo"','bar'],['foo,"\'','bar']], FastPostgresExtractor.new(s).result
  end
  
  def test_real_world_example1
    s = File.read(File.dirname(__FILE__)+"/example1.txt")
    result = [
      ["name", ["CV-PT10 H3"], "string", "Модель"],
      ["type",["настольный"],"string","Тип"],
      ["purpose", ["фото- и видеокамеры"], "string", "Сфера применения"],
      ["opora", ["резиновые"], "string", "Наконечники опор"],
      ["grey", ["true"], "boolean", "Серый цвет"]
    ]
    assert_equal result, PostgresExtractor.new(s).result
  end
    
  def test_fast_real_world_example1
    s = File.read(File.dirname(__FILE__)+"/example1.txt")
    result = [
      ["name", ["CV-PT10 H3"], "string", "Модель"],
      ["type",["настольный"],"string","Тип"],
      ["purpose", ["фото- и видеокамеры"], "string", "Сфера применения"],
      ["opora", ["резиновые"], "string", "Наконечники опор"],
      ["grey", ["true"], "boolean", "Серый цвет"]
    ]
    assert_equal result, FastPostgresExtractor.new(s).result
  end
    
  def test_real_world_example2
    s = File.read(File.dirname(__FILE__)+"/example2.txt")
    result = [
      ["vendor_text", ["Cavei"], "string", "Производитель"],
      ["name", ["CV-PT10 H3"], "string", "Модель"],
      ["type",["настольный"],"string","Тип"],
      ["purpose", ["фото- и видеокамеры"], "string", "Сфера применения"],
      ["construction", ["трипод"], "string", "Конструкция"],
      ["minheight", ["13.50"], "number", "Минимальная высота съемки, см"],
      ["maxheight", ["25.50"], "number", "Максимальная высота съемки, см"],
      ["maxweight", ["0.80"], "number", "Максимальная нагрузка, кг"],
      ["material", ["сплав алюминия"], "string", "Материал"],
      ["gnezdo", ['1/4"'], "string", "Винт под штативное гнездо камеры"],
      ["opora", ["резиновые"], "string", "Наконечники опор"],
      ["grey", ["true"], "boolean", "Серый цвет"]
    ]
    assert_equal result, PostgresExtractor.new(s).result
  end
  
  def test_fast_real_world_example2
    s = File.read(File.dirname(__FILE__)+"/example2.txt")
    result = [
      ["vendor_text", ["Cavei"], "string", "Производитель"],
      ["name", ["CV-PT10 H3"], "string", "Модель"],
      ["type",["настольный"],"string","Тип"],
      ["purpose", ["фото- и видеокамеры"], "string", "Сфера применения"],
      ["construction", ["трипод"], "string", "Конструкция"],
      ["minheight", ["13.50"], "number", "Минимальная высота съемки, см"],
      ["maxheight", ["25.50"], "number", "Максимальная высота съемки, см"],
      ["maxweight", ["0.80"], "number", "Максимальная нагрузка, кг"],
      ["material", ["сплав алюминия"], "string", "Материал"],
      ["gnezdo", ['1/4"'], "string", "Винт под штативное гнездо камеры"],
      ["opora", ["резиновые"], "string", "Наконечники опор"],
      ["grey", ["true"], "boolean", "Серый цвет"]
    ]
    assert_equal result, FastPostgresExtractor.new(s).result
  end
  
  def test_benchmark
    # return
    s = File.read(File.dirname(__FILE__)+"/example3.txt")
    Benchmark.bm(14) do |x|
      x.report("Speed (100):") { 100.times {PostgresExtractor.new(s).result } }
    end
  end
  
  def test_fast_benchmark
    # return
    s = File.read(File.dirname(__FILE__)+"/example3.txt")
    Benchmark.bm(14) do |x|
      x.report("Speed (100):") { 100.times {FastPostgresExtractor.new(s).result } }
    end
  end
  
  # def test_profile
  #   return
  #   s = File.read(File.dirname(__FILE__)+"/example3.txt")
  #   10.times {PostgresExtractor.new(s).result }
  #   result = RubyProf.profile do
  #     10.times {PostgresExtractor.new(s).result }
  #   end
  #   printer = RubyProf::GraphPrinter.new(result)
  #   printer.print(STDOUT, 0)
  # end
end
