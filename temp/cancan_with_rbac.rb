require 'rubygems'
require 'cancan'

class Ability
    include CanCan::Ability
  
    @@permissions = nil
  
    def initialize(user)
      self.clear_aliased_actions
  
      alias_action :index, :show, :to => :read
      alias_action :new,          :to => :create
      alias_action :edit,         :to => :update
      alias_action :destroy,      :to => :delete
  
      user ||= User.new
  
      # super user can do everything
      if user.role? :super
        can :manage, :all
      else
        # edit update self
        can :read, User do |resource|
          resource == user
        end
        can :update, User do |resource|
          resource == user
        end
        # enables signup
        can :create, User
=begin  
        user.roles.each do |role|
          if role.permissions
            role.permissions.each do |perm_name|
              unless Ability.permissions[perm_name].nil?
                can(Ability.permissions[perm_name]['action'].to_sym, Ability.permissions[perm_name]['subject_class'].constantize) do |subject|
                  Ability.permissions[perm_name]['subject_id'].nil? ||
                    Ability.permissions[perm_name]['subject_id'] == subject.id
                end
              end
            end
          end
        end
=end
      end
    end
  
    def self.permissions
      @@permissions ||= Ability.load_permissions
    end
  
    def self.load_permissions(file='permissions.yml')
      YAML.load_file("#{::Rails.root.to_s}/config/#{file}")
    end
  end

class User
  def initialize()
  end
  def role?(role)
    not (role == :super)
  end
end

a = Ability.new(nil)
require 'pp'

pp a
