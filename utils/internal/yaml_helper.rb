require 'psych'
module DTK
  module YamlHelper
    def self.dump_simple_form(obj)
      simple_form = simple_form_aux(obj)
      #To get around Pupept monkey patch which changes YAML.dump
      #  ::YAML.dump(simple_form)
      yaml_dump(simple_form)
    end
    
    def self.parse(content,opts={})
      ret = Hash.new
      if content.empty?
        ret
      else
        begin 
          ::YAML.load(content)
         rescue Exception => e
          ErrorUsage::DSLParsing::YAMLParsing.new("YAML #{e} in file",opts[:file_path])
        end
      end
    end

   private
    def self.yaml_dump(o)
      visitor = Psych::Visitors::YAMLTree.new
      visitor << o
      visitor.tree.yaml 
    end

    def self.simple_form_aux(obj)
      if obj.kind_of?(::Hash)
        ret = ::Hash.new
        obj.each_pair{|k,v|ret[string_form(k.to_s)] = simple_form_aux(v)}
        ret
      elsif obj.kind_of?(::Array)
        obj.map{|el|simple_form_aux(el)}
      elsif obj.kind_of?(::String)
        string_form(obj)
      elsif obj.kind_of?(::Fixnum)
        obj
      elsif obj.kind_of?(TrueClass) or obj.kind_of?(FalseClass)
        obj
      elsif obj.respond_to?(:to_s)
        string_form(obj.to_s)
      else 
        string_form(obj.inspect)
      end
    end

    def self.string_form(str)
      if str.respond_to?(:force_encoding)
        str.dup.force_encoding(Encoding::UTF_8)
      else
        str
      end
    end
  end
end
