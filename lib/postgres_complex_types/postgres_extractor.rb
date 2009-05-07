module PostgresComplexTypes
class PostgresExtractor
  
  attr_reader :result
  
  LEFT_CURL = "{".ord
  RIGHT_CURL = "}".ord
  LEFT_BRACKET = "(".ord
  RIGHT_BRACKET = ")".ord
  COMMA = ",".ord
  QUOTE = '"'.ord
  BACKSLASH = '\\'.ord
  
  def initialize(_val)
    @value_stack = []
    @pointer_stack = []
    @result = nil
    return if _val.nil? || _val.empty?
    @value = _val
    @ptr = 0
    parse_field
  end
  
  def current
    @value[@ptr]
  end
  
  def step
    @ptr += 1
  end
  
  def eov?
    @ptr >= @value.size
  end
  
  def parse_field
    if current == LEFT_CURL
      step
      extract_array
      step
    elsif current == LEFT_BRACKET
      step
      extract_row
      step
    else
      @result = @value 
      # puts "Extracted part #{@part.inspect}"
    end
  end
  
  def recursive_parse_field(new_value)
    @value_stack.push(@value)
    @pointer_stack.push(@ptr)
    @value = new_value
    @ptr = 0
    parse_field
    @value = @value_stack.pop
    @ptr = @pointer_stack.pop
  end
  
  def extract_array
    array = []
    # while !eov? do
    loop do
      step if current == COMMA
      break if current == RIGHT_CURL
      extract_array_value
      array << @result
    end
    @result = array
  end
  
  def extract_array_value
    in_quotes = false
    has_quoting = false
    if current == QUOTE
      in_quotes = true
      has_quoting = true
      step
    end
    array_item = ""
    # while !eov? do
    loop do
      # puts "Step: #{current}"
      current = self.current
      break if !in_quotes && (current == COMMA || current == RIGHT_CURL) # конец массива
      if in_quotes && current == QUOTE
        step
        break
      end

      if current == BACKSLASH
        has_quoting = true
        step
      end
      array_item << self.current
      step
    end
    return @result = nil if !has_quoting && 0 == array_item.casecmp('NULL')
    recursive_parse_field(array_item)
  end
  
  def extract_row
    array = []
    # while !eov? do
    loop do
      extract_row_value
      array << @result
      current = self.current
      step if current == COMMA
      break if current == RIGHT_BRACKET
    end unless self.current == RIGHT_BRACKET
    @result = array
  end
  
  def extract_row_value
    in_quotes = false
    has_quoting = false
    if current == QUOTE
      in_quotes = true
      has_quoting = true
      step
    end
    row_item = ""
    # while !eov? do
    loop do
      current = self.current
      if in_quotes && current == QUOTE && @value[@ptr + 1] == QUOTE
        row_item << QUOTE
        has_quoting = true
        step
        step
        next
      end
      if in_quotes && current == QUOTE
        step
        break
      end
      break if !in_quotes && (current == COMMA || current == RIGHT_BRACKET) # конец строчки
      if current == BACKSLASH
        has_quoting = true
        step
      end
      row_item << self.current
      step
    end
    if !has_quoting && row_item.empty?
      @result = nil
    else
      recursive_parse_field(row_item)
    end
  end
  
end
end
