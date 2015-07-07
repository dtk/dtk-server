module DTK
  class Clone
    module Global
      AssemblyChildren = [:node,:attribute_link,:port_link]
      NonParentNestedKeys = AssemblyChildren.inject({}) do |h,m|
        h.merge(m => {assembly_id: :component})
      end
      ForeignKeyOmissions = NonParentNestedKeys.inject({}) do |ret,kv|
        ret.merge(kv[0] => kv[1].keys)
      end
    end
  end
end
