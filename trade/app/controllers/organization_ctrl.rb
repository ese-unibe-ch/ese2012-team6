require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')
require_relative('../models/store/organization')

# Handles all requests concerning user registration
class Organization < Sinatra::Application
  include Store
  include Security
  include Storage

  before do
    @user = User.by_name(session[:name])
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

    org_name = params[:org_name].strip
    redirect 'error/invalid_username' unless StringChecker.is_valid_username?(org_name)

    org_desc = params[:org_desc]

    organization = Organization.named(org_name, :admin => @user, :description => org_desc)
    organization.save

    members = params[:member] || []
    members.each { |member| organization.add_member(User.by_name(member)) }

    redirect "/organizations"
  end

  # Get information about organization
  get '/organization/:organization_name' do
    redirect '/login' unless @user

    viewed_organization = Organization.by_name(params[:organization_name])
    is_my_organization = @user.is_member_of?(viewed_organization)
    i_am_admin = @user.is_admin_of?(viewed_organization)
    marked_down_description = RDiscount.new(viewed_organization.description, :smart, :filter_html)

    haml :organization_profile, :locals => {:viewed_organization => viewed_organization,
                                    :is_my_organization => is_my_organization,
                                    :i_am_admin => i_am_admin,
                                    :marked_down_description => marked_down_description.to_html
                                    }
  end

  # Shows selected organization
  get '/organization/:organization_name/edit' do
    redirect '/login' unless @user

    viewed_organization = Organization.by_name(params[:organization_name])

    redirect "/organization/#{viewed_organization.name}" unless @user.is_admin_of?(viewed_organization)

    is_my_organization = viewed_organization.has_member?(@user)
    i_am_admin = @user.is_admin_of?(viewed_organization)
    marked_down_description = viewed_organization.description

    haml :edit_organization, :locals => {:viewed_organization => viewed_organization,
                                           :is_my_organization => is_my_organization,
                                           :i_am_admin => i_am_admin,
                                           :marked_down_description => marked_down_description,
                                           :viewer => @user
                                          }
  end

  # handles a user add request to organization and determines whether the user is able to become admin of said organization
  post "/organization/:organization_name/add/:username/" do
    redirect '/login' unless @user

    organization = Organization.by_name(params[:organization_name])
    user         = User.by_name(params[:username])

    if !user.is_admin_of?(organization) and user.is_member_of?(organization)
      organization.add_admin(user)
    else
      organization.add_member(user)
    end
    #redirect "/organization/#{params[:organization_name]}"
    redirect (back + "#manage_admins")
  end

  # handles a user remove request from organization and determines whether the user can resign as admin or not,
  # THERE MUST ALWAYS BE AN ADMIN!
  post "/organization/:organization_name/remove/:username/" do
    redirect '/login' unless @user

    organization = Organization.by_name(params[:organization_name])
    user         = User.by_name(params[:username])

    if user.is_admin_of?(organization)
      organization.remove_admin(user)
    else
      organization.remove_member(user)
    end

    # fail if org has no admin
    fail if organization.admins.size == 0

    #redirect "/organization/#{params[:organization_name]}"
    redirect (back + "#manage_admins")
  end

  # Handles changing organization
  post '/organization/:org_name/edit' do
    redirect '/login' unless @user

    viewed_organization = params[:org_name]
    org_desc = params[:org_desc]
    organization = Organization.by_name(viewed_organization)
    organization.description = org_desc

    member_put = params[:member]
    member_rem = params[:rem]

    member_put.each {|username| organization.add_member(User.by_name(username))} unless member_put.nil?
    member_rem.each {|username| organization.remove_member(User.by_name(username))} unless member_put.nil?

    redirect "/organization/#{organization.name}"
  end

  # Handles organization's picture upload
  post '/organization/:name/pic_upload' do
    redirect '/login' unless @user

    viewed_organization = Organization.by_name(params[:name])
    file = params[:file_upload]
    redirect to("/organization/#{viewed_organization.name}") unless file

    redirect "/error/wrong_size" if file[:tempfile].size > 400*1024

    filename = Organization.id_image_to_filename(viewed_organization, file[:filename])
    uploader = PictureUploader.with_path("/images/organizations")
    viewed_organization.image_path = uploader.upload(file, filename)

    redirect back
  end

  # handles credit transfer request from user to organization
  post '/organization/:org_name/send_money' do
    redirect '/login' unless @user

    org_name = params[:org_name]
    org = Organization.by_name(org_name)

    fail unless @user.is_admin_of?(org)
    redirect "/error/wrong_transfer_amount" unless (StringChecker.is_numeric?(params[:gift_amount]) && Integer(params[:gift_amount]) >= 0)

    amount = params[:gift_amount].to_i
    success = org.send_money_to(@user, amount)

    redirect "/error/organization_credit_transfer_failed" unless success
    redirect back
  end
end