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

  # Shows site to create new organization
  get '/organization/new' do
    redirect '/login' unless @user

    haml :new_organization, :locals => { :org_name => "",
                                         :org_desc => "",
                                         :viewer => @user
                                       }
  end

  # Handles creating organization
  put '/organization' do
    redirect '/login' unless @user

    org_name = Security::StringChecker.destroy_script(params[:org_name])
    org_desc = params[:org_desc]

    organization = Store::Organization.named(org_name)
    organization.save
    organization.add_member(@user)
    organization.add_admin(@user)

    members = params[:member]

    for username in members
      organization.add_member(Store::User.by_name(username))
    end

    redirect "/organizations"
  end

  # Get information about organization
  get '/organization/:organization_name' do
    redirect '/login' unless @user

    viewed_organization = Store::Organization.by_name(params[:organization_name])
    is_my_organization = viewed_organization.organization_members.detect(@user) != nil
    i_am_admin = viewed_organization.organization_admin.detect(@user) != nil
    marked_down_description = RDiscount.new(viewed_organization.description, :smart, :filter_html)

    haml :organization, :locals => {:viewed_organization => viewed_organization,
                                    :is_my_organization => is_my_organization,
                                    :i_am_admin => i_am_admin,
                                    :marked_down_description => marked_down_description.to_html
                                    }
  end

  # Shows selected organization
  get '/organization_change/:organization_name' do
    redirect '/login' unless @user

    viewed_organization = Store::Organization.by_name(params[:organization_name])
    is_my_organization = viewed_organization.organization_members.detect(@user) != nil
    i_am_admin = viewed_organization.organization_admin.detect(@user) != nil
    marked_down_description = RDiscount.new(viewed_organization.description, :smart, :filter_html)

    haml :change_organization, :locals => {:viewed_organization => viewed_organization,
                                           :is_my_organization => is_my_organization,
                                           :i_am_admin => i_am_admin,
                                           :marked_down_description => marked_down_description.to_html,
                                           :viewer => @user
                                          }

  end

  # Handles changing organization
  put '/organization_change/:org_name' do
    redirect '/login' unless @user

    viewer = params[:org_name]
    organization = Store::Organization.by_name(viewer)
    member_put = params[:member]
    member_rem = params[:rem]

    for username in member_put
      organization.add_member(Store::User.by_name(username))
    end

    for username in member_rem
      organization.remove_member(Store::User.by_name(username))
    end

    redirect "/organization_change/:organization_name"
  end

  # Handles organization's picture upload
  post '/organization/:name' do
    redirect '/login' unless @user
    viewer = params[:name]
    file = params[:file_upload]
    redirect to("/organization/#{viewer}") unless file

    redirect "/error/wrong_size" if file[:tempfile].size > 400*1024

    filename = Store::Organization.id_image_to_filename(viewer, file[:filename])
    uploader = Storage::PictureUploader.with_path("/images/organizations")
    viewer.image_path = uploader.upload(file, filename)

    redirect '/organization_change'
  end
end