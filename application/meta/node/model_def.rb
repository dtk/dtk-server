
=begin
$model['key']['extends_base'] = 1;
$model['key']['implements_owner'] = 1;

$model['key']['fields']['status'] = array('type' => 'text', 'size' => 50, 'required' => true);
=end

#possible to have clean seperation of model field defs?

model[:node] = {}
model[:node][:has_ancestor_field] = true
model[:node][:fields] = {}
model[:node][:fields][:ds_attributes] = {:type => :json}
model[:node][:fields][:ds_key] = {:type => :varchar, :size => 50}


        has_ancestor_field()
        column :ds_attributes, :json
        column :ds_key, :varchar
        column :data_source, :varchar, :size => 25
        column :ds_source_obj_type, :varchar, :size => 25
        column :type, :varchar, :size => 25 # instance or template
        column :os, :varchar, :size => 25
        column :is_deployed, :boolean, :default => false
        column :architecture, :varchar, :size => 10 #e.g., 'i386'
       #TBD: in data source specfic now column :manifest, :varchar #e.g.,rnp-chef-server-0816-ubuntu-910-x86_32
        #TBD: experimenting whetehr better to make this actual or virtual columns
        column :image_size, :numeric, :size=>[8, 3] #in megs
        virtual_column :disk_size #in megs
        #TBD: can these virtual columns just be inherited
        virtual_column :parent_id
        virtual_column :parent_path
        foreign_key :data_source_id, :data_source, FK_SET_NULL_OPT
        many_to_one :library,:project
        one_to_many :attribute, :node_interface, :address_access_point
