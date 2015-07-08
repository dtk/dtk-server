class DTK::Repo
  class Diff
    Attributes = [:new_file,:renamed_file,:deleted_file,:a_path,:b_path,:diff]
    AttributeAssignFn = Attributes.inject({}){|h,a|h.merge(a => "#{a}=".to_sym)}
    def initialize(hash_input)
      hash_input.each{|a,v|send(AttributeAssignFn[a],v)}
    end

    def file_added
      @new_file && {path: @a_path}
    end

    def file_renamed
      @renamed_file && {old_path: @b_path, new_path: @a_path}
    end

    def file_deleted
      @deleted_file && {path: @a_path}
    end

    def file_modified
      ((@new_file || @deleted_file || @renamed_file) ? nil : true) && {path: @a_path} 
    end

    private

    attr_writer(*Attributes) 
  end
end
