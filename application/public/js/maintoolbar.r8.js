
//console.log(R8);

if (!R8.MainToolbar) {
	R8.prototype = function(){
		MainToolbar: function(){
			toggleSlider: function(){
				R8.utils.$("#sliderbar").slideToggle(100);
			}
		/*
		 add_item : function(toolbar_item){
		 //				function ToolbarItem() {}
		 //			    ToolbarItem.prototype = toolbar_item;
		 //			    return new ToolbarItem;
		 },
		 //this stores the list of currently loaded main toolbar sets
		 toolbar_sets : [],
		 //this stores teh list of currently loaded items that are referenced in sets
		 toolbar_items : [],
		 }
		 */
		}
	};
}
