class DTK::Repo
  class Diff
    Attributes = [:new_file,:renamed_file,:deleted_file,:a_path,:b_path,:diff]
    AttributeAssignFn = Attributes.inject(Hash.new){|h,a|h.merge(a => "#{a}=".to_sym)}
    def initialize(hash_input)
      hash_input.each{|a,v|send(AttributeAssignFn[a],v)}
    end

    def file_added?()
      @new_file or @renamed_file
    end

    def file_deleted?()
      @deleted_file or @renamed_file
    end

    def file_modified?()
      !!@diff and !(@new_file or @deleted_file or @renamed_file)
    end

   private
    attr_writer(*Attributes) 
  end
end
