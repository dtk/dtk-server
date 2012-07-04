class DTK::Repo
  class Diffs < Array
    def initialize(array_diff_hashes)
      super(array_diff_hashes.map{|hash|Diff.new(hash)})
    end

    #returns a hash with keys :file_renamed, :file_added, :file_deleted, :file_modified
    def ret_diff_types_summary()
      ret = Hash.new
      ret.merge!(:file_renamed => true) if find{|d|d.file_renamed?}
      ret.merge!(:file_added => true) if find{|d|d.file_added?}
      ret.merge!(:file_deleted => true)if find{|d|d.file_deleted?}
      ret.merge!(:file_modified => true) if find{|d|d.file_modified?}
      ret
    end
  end
end
