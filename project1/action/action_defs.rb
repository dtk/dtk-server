require SYSTEM_DIR + 'action_set/action_set'

module XYZ
  module Action
    class ImportChefRecipes < Top
      object Library
      method_name :import_chef_recipes   #not needed since default
      is_asynchronous

      #TBD: change so given in the Action set
      def self.ret_params(c,uri,request,href_prefix,opts)
        [IDHandle[:c=> c, :uri => request[:library_uri]],
        request[:cookbooks_uri]]
      end
    end
  end
end

module XYZ
  module ViewAction
    class ListLibrary < Top
    end
  end
end

module XYZ
  module ViewAction
    class ListTasks < Top
    end
  end
end

module XYZ
  module ViewAction
    class ListObjects < Top
    end
  end
end

module XYZ
  module ActionSet
    class ImportChefRecipes < Top

      actions Action::ImportChefRecipes, ViewAction::ListLibrary, ViewAction::ListTasks 
      params ViewAction::ListLibrary, 
        :uri => [:request, :library_uri],
        :opts => [:opts]

      params ViewAction::ListTasks,
	:uri => [:constant, "/task"],
        :opts => [:constant,{:depth=>:deep,:no_hrefs=>true}]

      #TBD: if params given for each action; then "actions" uneeded
      
      #TBD: challenge with doing same with non-view actions is that there is no set params
    end
  end
end


