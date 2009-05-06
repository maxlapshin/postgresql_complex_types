module PostgresComplexTypes
class FastPostgresExtractor
  require 'inline'
    
  inline do |builder|
    builder.prefix <<-C
#define LEFT_CURL '{'
#define RIGHT_CURL '}'
#define LEFT_BRACKET '('
#define RIGHT_BRACKET ')'
#define COMMA ','
#define QUOTE '"'
#define BACKSLASH '\\\\'

typedef struct PostgresParserData {
  int ptr;
  ID result;
  ID value;
} PostgresParserData;

void parse_field(VALUE);
void extract_array(VALUE);
void extract_array_value(VALUE self);
void extract_row(VALUE);
void extract_row_value(VALUE self);
void recursive_parse_field(VALUE self, VALUE new_value);
#define CURRENT (RSTRING(value)->ptr[data->ptr])
    C
    
    builder.c_singleton <<-C
    VALUE allocate() {
      struct PostgresParserData *data;
      data = (struct PostgresParserData *)malloc(sizeof(struct PostgresParserData));
      data->ptr = 0;
      data->result = rb_intern("@result");
      data->value = rb_intern("@value");
      return Data_Wrap_Struct(self, 0, free, data);
    }
    C
    
    builder.prefix <<-C
    void parse_field(VALUE self) {
      struct PostgresParserData *data;
      VALUE value;
      Data_Get_Struct(self, PostgresParserData, data);
      value = rb_ivar_get(self, data->value);
      if(data->ptr >= RSTRING_LEN(value)) {
        return;
      }
      if(CURRENT == LEFT_CURL) {
        data->ptr++;
        extract_array(self);
        data->ptr++;
      } else if (CURRENT == LEFT_BRACKET) {
        data->ptr++;
        extract_row(self);
        data->ptr++;
      } else {
        rb_ivar_set(self, data->result, value);
      }
    }

    void extract_array(VALUE self) {
      struct PostgresParserData *data;
      VALUE array = rb_ary_new();
      VALUE value;
      Data_Get_Struct(self, PostgresParserData, data);
      value = rb_ivar_get(self, data->value);
      for(; data->ptr < RSTRING_LEN(value) && CURRENT != RIGHT_CURL; ) {
        if(CURRENT == COMMA) {
          data->ptr++;
        }
        extract_array_value(self);
        rb_ary_push(array, rb_ivar_get(self, data->result));
      }
      rb_ivar_set(self, data->result, array);
    }


    void extract_array_value(VALUE self) {
      struct PostgresParserData *data;
      int in_quotes = 0;
      VALUE value;
      VALUE array_item = rb_str_new2("");
      Data_Get_Struct(self, PostgresParserData, data);
      value = rb_ivar_get(self, data->value);

      if(CURRENT == QUOTE) {
        in_quotes = 1;
        data->ptr++;
      }
      for(; data->ptr < RSTRING_LEN(value) ; ) {
        if(!in_quotes && (CURRENT == COMMA || CURRENT == RIGHT_CURL)) {
          break;
        }
        if(in_quotes && CURRENT == QUOTE) {
          data->ptr++;
          break;
        }
        
        if(CURRENT == BACKSLASH) {
          data->ptr++;
        }
        rb_str_buf_cat(array_item, RSTRING(value)->ptr+data->ptr, 1);
        data->ptr++;
      }
      recursive_parse_field(self, array_item);
    }
    
    void extract_row(VALUE self) {
      struct PostgresParserData *data;
      VALUE array = rb_ary_new();
      VALUE value;
      Data_Get_Struct(self, PostgresParserData, data);
      value = rb_ivar_get(self, data->value);
      for(; data->ptr < RSTRING_LEN(value) && CURRENT != RIGHT_BRACKET; ) {
        if(CURRENT == COMMA) {
          data->ptr++;
        }
        extract_row_value(self);
        rb_ary_push(array, rb_ivar_get(self, data->result));
      }
      rb_ivar_set(self, data->result, array);
    }
    
    void extract_row_value(VALUE self) {
      struct PostgresParserData *data;
      int in_quotes = 0;
      VALUE value;
      VALUE row_item = rb_str_new2("");
      Data_Get_Struct(self, PostgresParserData, data);
      value = rb_ivar_get(self, data->value);

      if(CURRENT == QUOTE) {
        in_quotes = 1;
        data->ptr++;
      }
      for(; data->ptr < RSTRING_LEN(value) ; ) {

        if(in_quotes && CURRENT == QUOTE && RSTRING(value)->ptr[data->ptr+1] == QUOTE) {
          rb_str_concat(row_item, INT2FIX(QUOTE));
          data->ptr += 2;
        } else {
          if(in_quotes && CURRENT == QUOTE) {
            data->ptr++;
            break;
          }
          if(!in_quotes && (CURRENT == COMMA || CURRENT == RIGHT_BRACKET)) {
            break;
          }
          if(CURRENT == BACKSLASH) {
            data->ptr++;
          }

          rb_str_buf_cat(row_item, RSTRING(value)->ptr+data->ptr, 1);
          data->ptr++;
        }
      }
      recursive_parse_field(self, row_item);
    }
    
    
    void recursive_parse_field(VALUE self, VALUE new_value) {
      VALUE value_stack, pointer_stack;
      struct PostgresParserData *data;
      Data_Get_Struct(self, PostgresParserData, data);

      value_stack = rb_iv_get(self, "@value_stack");
      pointer_stack = rb_iv_get(self, "@pointer_stack");
      rb_ary_push(value_stack, rb_ivar_get(self, data->value));
      rb_ary_push(pointer_stack, INT2FIX(data->ptr));
      rb_ivar_set(self, data->value, new_value);
      data->ptr = 0;
      parse_field(self);
      rb_ivar_set(self, data->value, rb_ary_pop(value_stack));
      data->ptr = FIX2INT(rb_ary_pop(pointer_stack));
    }
    C
    
    
    builder.c <<-C
    void _parse_field() {
      parse_field(self);
    }
    C
    
    
  end
  
  def initialize(_val)
    return unless _val.is_a?(String)
    @value_stack = []
    @pointer_stack = []
    @value = _val
    _parse_field
  end
  
  attr_reader :result
end
end
