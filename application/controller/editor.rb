

module XYZ
  class EditorController < AuthController

    def index
      return {:data=>''}
    end

    def load_file(id)
      files = {
        "1" => 'apache2/templates/default/apache2.conf.erb',
        "2" => 'apache2/metadata.json',
        "3" => 'apache2/metadata.rb',
        "4" => 'apache2/recipes/default.rb',
      }
      file_path = R8::Config[:editor_file_path]+'/'+files[id]
      file_contents=IO.read(file_path)

      return {:data => file_contents}
    end
  end
end
