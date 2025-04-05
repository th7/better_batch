# final, a, b = MultiEnum.new.enums(2) do |a, b|
#   items.each do |item|
#     if item[:a]
#       a << item
#     else
#       b << item
#     end
#   end
# end

# a.each_slice(1000) { |items| p items }
# b.each_slice(1000) { |items| p items }

# final.each_slice(1000) { |items| p items }

module BetterBatch
  class MultiEnum
    def enums(count, &block)
      laziers = count.times.map { LazierEnum.new }
      final = Enumerator.new do |final|
        normies = nest(count, final, &block)
        normies.zip(laziers) do |normie, lazier|
          normie.each_slice(lazier.per_slice) do |items|
            lazier.each_slice_block.call(items)
          end
        end
      end
      [final, *laziers]
    end

    private

    def nest(count, final_yielder, this_count=1, previous_yielders=[], normies_yielder=nil, &block)
      if normies_yielder
        if count == this_count
          normies_yielder << Enumerator.new do |y|
            lazier_yielder = LazierYielder.new(y, final_yielder)
            block.call(*previous_yielders, lazier_yielder)
          end
        else
          normies_yielder << Enumerator.new do |y|
            lazier_yielder = LazierYielder.new(y, final_yielder)
            nest(count, final_yielder, this_count + 1, previous_yielders << lazier_yielder, normies_yielder, &block)
          end
        end
      else
        Enumerator.new do |y|
          nest(count, final_yielder, this_count, previous_yielders, y, &block)
        end
      end
    end
  end

  class LazierEnum
    attr_reader :per_slice, :each_slice_block

    def ready?
      @each_slice_block.is_a?(Proc)
    end

    def each_slice(per_slice, &block)
      @per_slice = per_slice
      @each_slice_block = block
    end
  end

  class LazierYielder
    def initialize(wrapped_yielder, final_yielder)
      @wrapped_yielder = wrapped_yielder
      @final_yielder = final_yielder
    end

    def <<(item)
      @wrapped_yielder << item
      @final_yielder << item
    end
  end
end
