
require 'daemons'

module XYZ
  class R8Daemons
    class << self
      def run(script, opts = {})
  ::Daemons.run(script, opts)
      end
    end
  end
end
