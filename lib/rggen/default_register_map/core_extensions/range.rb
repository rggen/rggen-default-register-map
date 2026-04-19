# frozen_string_literal: true

class Range
  if Gem::Version.new(RUBY_VERSION) < '3.3.0'
    # Original from:
    # https://github.com/rubyworks/facets/blob/3.1.0/lib/core/facets/range/overlap.rb
    def overlap?(other)
      include?(other.first) || other.include?(first)
    end
  end
end
