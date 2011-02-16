module XYZ
  class AssemblyController < Controller

    def test_get_items(id)
      assembly = id_handle(id,:component).create_object()
      item_list = assembly.get_items()

      return {
        :data=>item_list
      }
    end

  end
end