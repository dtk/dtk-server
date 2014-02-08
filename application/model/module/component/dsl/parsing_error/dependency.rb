module DTK
  class ComponentDSL
    class ParsingError
      class Dependency < self
        def self.create(msg,dep_choice,*args)
          dep = (dep_choice.respond_to?(:print_form) ? dep_choice.print_form() : dep_choice)
          hash_params = {
            :base_cmp => dep_choice.base_cmp_print_form(),
            :dep_cmp => dep_choice.dep_cmp_print_form(),
            :dep => dep
          }
          create_with_hash_params(msg,hash_params,*args)
        end
      end
    end
  end
end
