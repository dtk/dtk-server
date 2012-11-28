module XYZ
  module CreateThread
    def self.defer(&block)
      Ramaze::defer(&wrap(&block))
    end

    private

    # wrap() - Added this part of code so if thread fails we will know imedietly. Helps with development,
    # in case there is some internal logic that expects some thread to fail error messages can be 
    # ignored or this call

    def self.wrap(&block)
      return lambda do
        begin
          yield
        rescue Exception => e
          Log.error "[ERROR IN THREAD] #{e.message}"
          Log.error e
        end
      end
    end
  end
end
