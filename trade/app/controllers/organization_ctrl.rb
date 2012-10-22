require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')
require_relative('../models/store/organization')

# Handles all requests concerning user registration
class Organization < Sinatra::Application

  before do
    @user = Store::User.by_name(session[:name])
  end

  # Shows registration form
  get '/organizations' do
    redirect '/login' unless @user

    haml :all_organizations
  end

  get "/organization/:organization_name" do
    redirect '/login' unless @user

    viewed_organization = Store::Organization.by_name(params[:organization_name])
    is_my_organization = viewed_organization.organization_members.detect(@user)
    i_am_admin = viewed_organization.organization_admin.detect(@user)
    marked_down_description = RDiscount.new(viewed_organization.description, :smart, :filter_html)

    haml :organization, :locals => {
        :viewed_organization => viewed_organization,
        :is_my_organization => is_my_organization,
        :i_am_admin => i_am_admin,
        :marked_down_description => marked_down_description.to_html
    }

  end

  post "/organization/:organization_name/:username/add" do
    redirect '/login' unless @user

    organization = Store::Organization.by_name(param[:organization_name])
    user         = Store::User.by_name(param[:username])

    if organization.organization_admin.include?(user)
      organization.add_admin(user)
    else
      organization.add_member(user)
    end

  end

  post "/organization/:organization_name/:username/remove" do
    redirect '/login' unless @user

    organization = Store::Organization.by_name(param[:organization_name])
    user         = Store::User.by_name(param[:username])

    if organization.organization_admin.include?(user)
      organization.remove_admin(user)
    else
      organization.remove_member(user)
    end

  end


end