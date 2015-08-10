module AdminPanelMixin
		@@length = 254


	def delete_object(page)
		page.search_for_object(@search_value)
		page.press_delete_link(@search_value)
		page.search_for_object(@search_value)
		!page.object_exists?(@search_value)
	end

	def create_object(page)
		page.open_create_page
		page.enter_data(get_data)
		page.press_create_button
	end

	def get_too_long_name
   		name="" 
   		@@length.times{ name+="a"} 
   		name 
	end

end
