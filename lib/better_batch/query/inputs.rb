module BetterBatch
  class Query
    Inputs = Struct.new(
      :table_name,
      :input_columns,
      :column_types,
      :unique_columns,
      :primary_key,
      :now_on_insert,
      :now_on_update,
      :returning,
      keyword_init: true
    )

    # this strange (to me) setup avoids method redefinition warnings
    module InstanceOverrides
      def returning
        case self[:returning]
        when nil
          []
        when '*'
          self.column_types.keys
        else
          self[:returning]
        end
      end

      def now_on_insert
        return [] if self[:now_on_insert].nil?

        self[:now_on_insert]
      end

      def now_on_update
        return [] if self[:now_on_update].nil?

        self[:now_on_update]
      end
    end

    class Inputs
      prepend InstanceOverrides
    end
  end
end
