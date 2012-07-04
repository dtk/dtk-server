class DTK::Repo
  class Diffs < Array
    class Summary < ::DTK::SimpleHashObject
      def no_diffs?()
        keys().empty?
      end
      def no_added_or_deleted_files?()
        not (self[:files_renamed] or self[:files_added] or self[:files_deleted])
      end

      def meta_file_changed?()
        self[:files_modified] and !!self[:files_modified].find{|r|r[:path] =~ /^r8meta/}
      end

      #note: in paths_to_add and paths_to_delete rename appears both since rename can be accomplsihed by a add + a delete 
      def paths_to_add()
        (self[:files_added]||[]).map{|r|r[:path]} + (self[:files_renamed]||[]).map{|r|r[:new_path]}
      end
      def paths_to_delete()
        (self[:files_deleted]||[]).map{|r|r[:path]} + (self[:files_renamed]||[]).map{|r|r[:old_path]}
      end
    end

    def initialize(array_diff_hashes)
      super(array_diff_hashes.map{|hash|Diff.new(hash)})
    end

    #returns a hash with keys :file_renamed, :file_added, :file_deleted, :file_modified
    def ret_summary()
      [:renamed,:added,:deleted,:modified].inject(Summary.new) do |h,cnd|
        res = map{|diff|diff.send("file_#{cnd}".to_sym)}.compact
        res.empty? ? h : h.merge("files_#{cnd}".to_sym => res)
      end
    end
  end
end
