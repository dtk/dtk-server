class DTK::Repo
  class Diffs < Array
    def initialize(array_diff_hashes)
      super(array_diff_hashes.map{|hash|Diff.new(hash)})
    end
  end
end
