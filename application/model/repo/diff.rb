class DTK::Repo
  class Diff
    Attributes = [:new_file,:renamed_file,:deleted_file,:a_path,:b_path,:diff]
    AttributeAssignFn = Attributes.inject(Hash.new){|h,a|h.merge(a => "#{a}=".to_sym)}
    attr_accessor(*Attributes) 
    def initialize(hash_input)
      hash_input.each{|a,v|send(AttributeAssignFn[a],v)}
    end
  end
end
