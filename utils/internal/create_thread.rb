module XYZ
  module CreateThread
    def self.defer(&block)
      Ramaze::defer(&block)
    end
  end
end
