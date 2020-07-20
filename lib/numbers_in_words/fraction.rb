# frozen_string_literal: true

module NumbersInWords
  class Fraction
    attr_reader :denominator, :numerator, :attributes

    def self.in_words(that)
      r = that.rationalize(EPSILON)

      NumbersInWords
        .fraction(denominator: r.denominator, numerator: r.numerator)
        .in_words
    end

    def initialize(denominator:, numerator: 1, attributes: nil)
      @denominator = denominator
      @numerator = numerator
      @attributes = attributes || NumbersInWords::ExceptionalNumbers::DEFINITIONS[denominator] || {}
    end

    def to_r
      return 0.0 if denominator == Float::INFINITY

      (numerator.to_f / denominator.to_f).rationalize(EPSILON)
    end

    def lookup_keys
      key = in_words
      key_2 = strip_punctuation(key.split(' ')).join(' ')

      key_3 = "a #{key}"
      key_4 = "an #{key}"
      key_5 = "a #{key_2}"
      key_6 = "an #{key_2}"
      [key, key_2, key_3, key_4, key_5, key_6].uniq
    end

    def in_words
      if denominator == Float::INFINITY
        # We've reached the limits of ruby's number system
        # by the time we get to a googolplex (10 ** (10 ** 100))
        # I suppose we could also call this an 'infinitieth'
        return pluralize? ? 'googolplexths' : 'googolplexth'
      end

      NumbersInWords.in_words(numerator) + ' ' + fraction
    end

    def ordinal
      pluralize? ? pluralized_ordinal_in_words : singular_ordinal_in_words
    end

    def fraction
      pluralize? ? pluralized_fraction : singular_fraction
    end

    private

    def strip_punctuation(words)
      words.map { |w| w.gsub(/^a-z/, ' ') }
    end

    def pluralized_fraction
      fraction_plural || pluralized_ordinal_in_words
    end

    def singular_fraction
      fraction_singular || singular_ordinal_in_words
    end

    def pluralized_ordinal_in_words
      pluralized_ordinal || denominator_ordinal_in_words
    end

    def singular_ordinal_in_words
      singular_ordinal || denominator_ordinal_in_words
    end

    def singular_ordinal
      attributes[:ordinal]
    end

    def pluralized_ordinal
      singular_ordinal && singular_ordinal + 's'
    end

    def pluralize?
      numerator > 1
    end

    def denominator_ordinal_in_words
      if denominator > 100
        # one hundred and second
        with_remainder(100, ' and ')
      elsif denominator > 19
        # two thirty-fifths
        with_remainder(10, '-')
      else
        # one seventh
        singular = NumbersInWords.in_words(denominator) + 'th'
        pluralize? ? singular + 's' : singular
      end
    end

    def plural
      exception? && (fraction_plural || singular + 's') || ordinal_plural
    end

    def singular
      (exception? && exception[:singular]) || ordinal
    end

    def with_remainder(mod, join_word)
      rest = denominator % mod
      main = denominator - rest
      main = NumbersInWords.in_words(main)

      main = main.gsub(/^one /, '') if pluralize?

      rest_zero(rest, main) || joined(main, rest, join_word)
    end

    def joined(main, rest, join_word)
      main +
        join_word +
        self.class.new(numerator: numerator, denominator: rest).ordinal
    end

    def rest_zero(rest, main)
      return unless rest.zero?

      if pluralize?
        main + 'ths'
      else
        main + 'th'
      end
    end

    def exception?
      exception&.is_a?(Hash)
    end

    def exception
      attributes[:fraction]
    end

    def fraction_singular
      exception? && exception[:singular]
    end

    def fraction_plural
      exception? && exception[:plural]
    end
  end
end
