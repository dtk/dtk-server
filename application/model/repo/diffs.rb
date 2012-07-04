class DTK::Repo
  class Diffs < Array
    class Summary < ::DTK::SimpleHashObject
      def no_diffs?()
        keys().empty?
      end
      def no_added_or_deleted_files?()
        not (self[:file_renamed] or self[:file_added] or self[:file_deleted])
      end
    end

    def initialize(array_diff_hashes)
      super(array_diff_hashes.map{|hash|Diff.new(hash)})
    end

    #returns a hash with keys :file_renamed, :file_added, :file_deleted, :file_modified
    def ret_summary()
      [:file_renamed,:file_added,:file_deleted,:file_modified].inject(Summary.new) do |h,cnd|
        res = map{|diff|diff.send(cnd)}.compact
        res.empty? ? h : h.merge(cnd => res)
      end
    end
  end
end
