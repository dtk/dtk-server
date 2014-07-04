module DTK
  class Namespace < Model
    def self.common_columns()
      [
        :id,
        :group_id,
        :display_name,
        :name,
        :remote
      ]
    end
  end
end
