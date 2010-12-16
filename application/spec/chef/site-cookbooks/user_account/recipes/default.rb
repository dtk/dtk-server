((node[:user_account]||{})[:list]||[]).each do |el| 
  process_instance "intance" do
    element el
  end
end
