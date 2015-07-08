module Puppet
end
require 'puppet/resource'
require 'puppet/type'
require 'puppet/parser'

module DTK; class ConfigAgent; class Adapter::Puppet
  r8_nested_require('parser','external_dependency')
  r8_nested_require('parser','modulefile')
  r8_nested_require('parser','metadata_file')

  module ParserMixin
    def parse_provider_specific_dependencies?(impl_obj)
      # use metadata file source over modulefile
      MetadataFile.parse?(impl_obj) ||  Modulefile.parse?(impl_obj)
    end

    def parse_given_module_directory(impl_obj)
      # only handling parsing of .pp now
      # DTK-1951 leave this to support backward compatibility
      manifest_file_paths = impl_obj.all_file_paths().select{|path|path =~ /^manifests.+\.pp$/}

      # look for manifest files in puppet/manifests (DTK-1951)
      if manifest_file_paths.empty?
        manifest_file_paths = impl_obj.all_file_paths().select{|path|path =~ /^puppet\/manifests.+\.pp$/}
      end

      ret = ParseStructure::TopPS.new()
      opts = {just_krt_code: true}
      errors_cache = nil
      manifest_file_paths.each do |file_path|
        Log.info("Calling #{type()} and dtk processor on file #{file_path}")
        begin
          krt_code = parse_given_file_path__manifest(file_path,impl_obj,opts)
          ret.add_children(krt_code) unless errors_cache #short-circuit once first error found
         rescue ParseErrorsCache => errors
          errors_cache = (errors_cache ? errors_cache.add(errors) : errors)
         rescue ParseError => error
          errors_cache = (errors_cache ? errors_cache : ParseErrorsCache.new(type())).add(error,Opts.new(file_path: file_path))
        end
      end
      raise errors_cache.create_error() if errors_cache
      ret
    end

    # returns [config agent type, parse]
    # types are :component_defs, :template, :r8meta
    def parse_given_file_content(file_path,file_content)
      ret = [nil,nil]
      if file_path =~ /\.pp$/
        ret[0] = :component_defs
        ret[1] = parse_given_file_content__manifest(file_content)
      end
      ret
    end

    private

    PuppetParserLock = Mutex.new

    def parse_given_file_path__manifest(file_path,impl_obj,opts={})
      file_content = RepoManager.get_file_content({path: file_path},impl_obj)
      parse_given_file_content__manifest(file_content,opts.merge(file_path: file_path))
    end

    def parse_given_file_content__manifest(file_content,opts={})
      synchronize_and_handle_puppet_globals({code: file_content, ignoreimport: false},opts) do
        environment = "production"
        node_env = ::Puppet::Node::Environment.new(environment)
        known_resource_types = ::Puppet::Resource::TypeCollection.new(node_env)
        # needed to make more complicared because cannot call krt = ::Puppet::Node::Environment.new(environment).known_resource_types because perform_initial_import needs import set to false, but rest needs it set to true
        # fragment from perform_initial_import call with ::Puppet[:ignoreimport] = true set in middle
        parser = ::Puppet::Parser::Parser.new(node_env)
        parser.string = file_content
        ::Puppet[:ignoreimport] = true
        initial_import = parser.parse

        known_resource_types.import_ast(initial_import,"")
        krt_code = known_resource_types.hostclass("").code
        opts[:just_krt_code] ? krt_code : ParseStructure::TopPS.new(krt_code)
      end
    end

    def synchronize_and_handle_puppet_globals(global_assignments,opts={},&_block)
      ret = nil
      PuppetParserLock.synchronize do
        begin
          current_vals = global_assignments.keys.inject({}){|h,k|h.merge(k => ::Puppet[k])}
          curent_krt = Thread.current[:known_resource_types]
          global_assignments.each{|k,v|::Puppet[k]=v}
          Thread.current[:known_resource_types] = nil
          ret = yield
         rescue ::Puppet::Error => e
          raise normalize_puppet_error(e,opts[:file_path])
         rescue Exception => e
          raise e
         ensure
          current_vals.each{|k,v|::Puppet[k]=v}
          Thread.current[:known_resource_types] = curent_krt
        end
      end
      ret
    end

    def normalize_puppet_error(puppet_error,file_path)
      file_path ||= puppet_error.file || find_file_path(puppet_error.message)
      # TODO: strip stuff off error message
      msg = strip_message(puppet_error.message)
      opts = {file_path: file_path}
      unless msg_has_line_num?(msg)
        if line = (puppet_error.line || find_line(puppet_error.message))
          opts.merge!(line_num: line)
        end
      end
      ParseError.new(msg,opts)
    end

    def find_file_path(msg)
      if msg =~ /at ([^ ]+):[0-9]+$/
        $1
      end
    end

    def msg_has_line_num?(msg)
      # just heursitic
      (!!find_line(msg)) ||
        (msg =~ /[0-9]+/ && msg =~ /at line/)
    end

    def  find_line(msg)
      if msg =~ /:([0-9]+$)/
        $1
      end
    end

    def strip_message(msg)
      ret = msg
      ret = ret.gsub(/Could not parse for environment production: /,"")
      ret = ret.gsub(/at [^ ]+:[0-9]+$/,"")
      ret
    end
  end
end; end; end

# monkey patches
class Puppet::Parser::AST::Definition
  attr_reader :name
end
####
