((node[:user_account]||{})[:list]||[]).each do |el| 
  process_instance "instance" do
    element el
  end
end
