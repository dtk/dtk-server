module DTK; class CommandAndControl::IAAS::Bosh
  class Client
    module ReleasesMixin
      # Returns the VersionObject representing the latest relese if release_name exists
      def latest_release_version?(release_name)
        if release = Releases.new(self).release(release_name)
          release.latest_version_object
        end
      end
    end
    
    class Releases < Hash
      def initialize(client)
        super()
        client.releases.each do |release_hash| 
          name = release_hash['name']
          versions = release_hash['release_versions']
          merge!(name => Release.new(name, versions))
        end
      end

      def release(release_name)
        self[release_name]
      end
    end

    class Release
      def initialize(name, version_array)
        @name = name
        @version_objects = version_array.map { |version_hash| version_object(version_hash) }
      end

      def latest_version_object
        @version_objects.sort { |v1, v2| version_relation(v1, v2) }.last
      end

      private

      VersionObject = Struct.new(:version, :commit_hash, :uncommitted_changes, :currently_deployed, :job_names)
      def version_object(version_hash)
        VersionObject.new(
          version_hash['version'],
          version_hash['commit_hash'],
          version_hash['uncommitted_changes'],
          version_hash['currently_deployed'],
          version_hash['job_names']
        )
      end

      def version_relation(version_struct1, version_struct2)
        v1 = version_struct1.version
        v2 = version_struct2.version
        if dev_num?(v1) and dev_num?(v2)
          dev_num?(v1) <=> dev_num?(v2)
        else
          # default
          # TODO: right now just alpha sort; need to distingusih between dev and final
          v1 <=> v2
        end
      end

      def dev_num?(version)
        #TODO: just looking for '0+dev.NUM
        $1.to_i if version =~ /^0\+dev\.([0-9]+$)/
      end
    end
  end
end; end
