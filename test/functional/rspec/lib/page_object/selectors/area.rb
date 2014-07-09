Capybara.add_selector(:header) do
  xpath { "//div[@class=\"navbar-inner\"]" }
end

Capybara.add_selector(:table) do
  xpath { "//div[@class=\"container\"]/table[@class=\"table table-bordered table-modified\"]" }
end