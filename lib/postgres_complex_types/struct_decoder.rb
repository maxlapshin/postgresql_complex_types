module PostgresComplexTypes
  module StructDecoder
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def typecast(obj)
        if obj.is_a?(String)
          unmarshall(obj)
        else
          nil
        end
      end
      
      def unmarshall(parts)
        parts = (Array(parts) + [nil]*members.size)[0,members.size]
        postprocess(new(*parts))
      end
      
      def postprocess(struct)
        struct
      end
    end
  end
end
