module DTK; class Repo
  class Diffs < Array
    class Summary < SimpleHashObject
      def initialize(diffs_hash=nil)
        super()
        (diffs_hash||{}).each do |t,v|
          t = t.to_sym
          if DiffTypes.include?(t)
            self[t] = v
          else
            Log.error("unexpected sumamry diff type (#{t})")
          end
        end
      end
      def no_diffs?()
        keys().empty?
      end
      def no_added_or_deleted_files?()
        not (self[:files_renamed] or self[:files_added] or self[:files_deleted])
      end

      def meta_file_changed?()
        (self[:files_modified] and !!self[:files_modified].find{|r|ComponentDSL.isa_dsl_filename?(path(r))}) or
        (self[:files_added] and !!self[:files_added].find{|r|ComponentDSL.isa_dsl_filename?(path(r))})
      end

      def file_changed?(path)
        self[:files_modified] and !!self[:files_modified].find{|r|path(r) == path}
      end

      #note: in paths_to_add and paths_to_delete rename appears both since rename can be accomplsihed by a add + a delete 
      def paths_to_add()
        (self[:files_added]||[]).map{|r|path(r)} + (self[:files_renamed]||[]).map{|r|r[:new_path]}
      end
      def paths_to_delete()
        (self[:files_deleted]||[]).map{|r|path(r)} + (self[:files_renamed]||[]).map{|r|r[:old_path]}
      end
      DiffNames = [:renamed,:added,:deleted,:modified]
      DiffTypes = DiffNames.map{|n|"files_#{n}".to_sym}

     private
      def path(r)
        r["path"]||r[:path]
      end

    end

    def initialize(array_diff_hashes)
      super(array_diff_hashes.map{|hash|Diff.new(hash)})
    end

    #returns a hash with keys :file_renamed, :file_added, :file_deleted, :file_modified
    def ret_summary()
      DiffTypesAndMthods.inject(Summary.new) do |h,(diff_type, diff_method)|
#        diff_type, diff_method = tm
        res = map{|diff|diff.send(diff_method)}.compact
        res.empty? ? h : h.merge(diff_type => res)
      end
    end
    DiffTypesAndMthods = Summary::DiffNames.map{|n|["files_#{n}".to_sym,"file_#{n}".to_sym]}
  end
end; end
