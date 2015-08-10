require './lib/mixins/admin_panel_mixins'

class PanelObject
	attr_accessor :search_value

	def initialize
		@search_value=''
	end

	def get_data
		{}
	end

end

class UserGroup < PanelObject
	include AdminPanelMixin
	attr_accessor :name
	attr_accessor :desc

	def initialize(name, desc)
		super()
		@name=name
		@desc=desc
		@search_value=name
	end

	def get_data
		return {name: @name, desc: @desc}
	end
end



class User < PanelObject
	include AdminPanelMixin
	attr_accessor :username
	attr_accessor :password
	attr_accessor :first
	attr_accessor :last
	attr_accessor :email
	attr_accessor :ns
	attr_accessor :group

	def initialize(username, password, first, last, email, ns, group)
		@username=username
		@password=password
		@first=first
		@last=last
		@email=email
		@ns=ns
		@group=group
		@search_value=username
	end

	def get_data
		{username: @username,
			password: @password,
			first: @first,
			last: @last,
			email: @email,
			ns: @ns,
			group: @group}
	end
end


class Namespace
	include AdminPanelMixin
	attr_accessor :name
	attr_accessor :owner
	attr_accessor :group
	attr_accessor :user_perm
	attr_accessor :group_perm
	attr_accessor :other_perm

	def initialize(name, owner, group, user_perm, group_perm, other_perm)
		@name=name
		@owner=owner
		@group=group
		@user_perm=user_perm
		@group_perm=group_perm
		@other_perm=other_perm
		@search_value=name
	end

	def get_data
		{
			name: name,
			owner: owner,
			group: group,
			user_perm: user_perm,
			group_perm: group_perm,
			other_perm: other_perm
		}
	end	
end

