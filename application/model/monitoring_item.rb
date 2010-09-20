module XYZ
  class MonitoringItem < Model
    set_relation_name(:monitoring,:item)
    class << self
      def up()
        column :service_name, :varchar, :size => 50
        column :condition_name, :varchar, :size => 50
        column :condition_description, :varchar
        column :enabled, :boolean, :default => true
        column :params, :json
        #TODO: this may be be broken out as an object
        column :attributes_to_monitor, :json
        many_to_one :component, :node
      end
    end

    ###### helper fns
   private

    ### virtual column defs
  end
end

