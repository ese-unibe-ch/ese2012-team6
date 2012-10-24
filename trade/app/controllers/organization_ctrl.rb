require 'haml'
require_relative('../models/store/item')
require_relative('../models/store/user')
require_relative('../models/store/organization')

# Handles all requests concerning user registration
class Organization < Sinatra::Application

  before do
    @user = Store::User.by_id(session[:name])
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
    redirect 'error/no_name' if params[:org_name]==""

    org_name = Security::StringChecker.destroy_script(params[:org_name])
    org_desc = params[:org_desc]

    organization = Store::Organization.named(org_name)
    organization.save
    organization.add_member(@user)
    organization.add_admin(@user)
    organization.description = org_desc
    members = params[:member]

    if members != nil
      for username in members
        organization.add_member(Store::User.by_id(username))
      end
    end

    redirect "/organizations"
  end

  # Get information about organization
  get '/organization/:organization_name' do
    redirect '/login' unless @user

    viewed_organization = Store::Organization.by_name(params[:organization_name])
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

    viewed_organization = Store::Organization.by_name(params[:organization_name])

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

  post "/organization/:organization_name/add/:username/" do
    redirect '/login' unless @user

    organization = Store::Organization.by_name(params[:organization_name])
    user         = Store::User.by_id(params[:username])

    if !user.is_admin_of?(organization) and user.is_member_of?(organization)
      organization.add_admin(user)
    else
      organization.add_member(user)
    end
    #redirect "/organization/#{params[:organization_name]}"
    redirect (back + "#manage_admins")
 end

  post "/organization/:organization_name/remove/:username/" do
    redirect '/login' unless @user

    organization = Store::Organization.by_name(params[:organization_name])
    user         = Store::User.by_id(params[:username])

    if user.is_admin_of?(organization)
      organization.remove_admin(user)
    else
      organization.remove_member(user)
    end

    #redirect "/organization/#{params[:organization_name]}"
    redirect (back + "#manage_admins")

  end

  # Handles changing organization
  post '/organization/:org_name/edit' do
    redirect '/login' unless @user

    viewed_organization = params[:org_name]
    org_desc = params[:org_desc]
    organization = Store::Organization.by_name(viewed_organization)
    organization.description = org_desc

    member_put = params[:member]
    member_rem = params[:rem]

    if member_put != nil
      for username in member_put
        organization.add_member(Store::User.by_id(username))
      end
    end

    if member_rem != nil
      for username in member_rem
        organization.remove_member(Store::User.by_id(username))
      end
    end

    redirect "/organization/#{organization.name}"
  end

  # Handles organization's picture upload
  post '/organization/:name/pic_upload' do
    redirect '/login' unless @user

    viewed_organization = Store::Organization.by_name(params[:name])
    file = params[:file_upload]
    redirect to("/organization/#{viewed_organization.name}") unless file

    redirect "/error/wrong_size" if file[:tempfile].size > 400*1024

    filename = Store::Organization.id_image_to_filename(viewed_organization, file[:filename])
    uploader = Storage::PictureUploader.with_path("/images/organizations")
    viewed_organization.image_path = uploader.upload(file, filename)

    redirect back
  end

  post '/organization/:org_name/send_money' do
    redirect '/login' unless @user

    org_name = params[:org_name]
    org = Store::Organization.by_name(org_name)

    fail unless @user.is_admin_of?(org)
    redirect "/error/wrong_transfer_amount" unless (!!(params[:gift_amount] =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(params[:gift_amount]) >= 0)

    amount = Integer(params[:gift_amount])
    success = org.send_money_to(@user, amount)

    redirect "/error/organization_credit_transfer_failed" unless success
    redirect back
  end
end