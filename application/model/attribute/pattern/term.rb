module DTK; class Attribute
  class Pattern
    module Term
      def self.canonical_form(type,term)
        "#{type}#{LDelim}#{term}#{RDelim}"
      end
      def self.extract_term?(canonical_form)
        if canonical_form =~ FilterFragmentRegexp
          $1 
        end
      end
      LDelim = '<'
      RDelim = '>'
      EscpLDelim = "\\#{LDelim}"
      EscpRDelim = "\\#{RDelim}"
      FilterFragmentRegexp = Regexp.new("[a-z]#{EscpLDelim}([^#{EscpRDelim}]+)#{EscpRDelim}")
    end
  end
end; end
