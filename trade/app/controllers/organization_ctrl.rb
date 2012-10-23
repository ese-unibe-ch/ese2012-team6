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

    if params[:org_name]==""
      redirect 'error/no_name'
    end

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
        organization.add_member(Store::User.by_name(username))
      end
    end

    redirect "/organizations"
  end

  # Get information about organization
  get '/organization/:organization_name' do
    redirect '/login' unless @user

    viewed_organization = Store::Organization.by_name(params[:organization_name])
    is_my_organization = viewed_organization.has_member?(@user)
    i_am_admin = viewed_organization.has_admin?(@user)
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

    if viewed_organization.has_member?(@user)
      is_my_organization = true
    else is_my_organization = false
    end

    if viewed_organization.has_admin?(@user)
      i_am_admin = true
    else i_am_admin = false
    end

    marked_down_description = viewed_organization.description

    haml :change_organization, :locals => {:viewed_organization => viewed_organization,
                                           :is_my_organization => is_my_organization,
                                           :i_am_admin => i_am_admin,
                                           :marked_down_description => marked_down_description,
                                           :viewer => @user
                                          }
  end

  post "/organization/:organization_name/add/:username/" do
    redirect '/login' unless @user

    organization = Store::Organization.by_name(params[:organization_name])
    user         = Store::User.by_name(params[:username])

    if !organization.has_admin?(user) and organization.has_member?(user)
      organization.add_admin(user)
    else
      organization.add_member(user)
    end
    redirect "/organization/#{params[:organization_name]}"
 end

  post "/organization/:organization_name/remove/:username/" do
    redirect '/login' unless @user

    organization = Store::Organization.by_name(params[:organization_name])
    user         = Store::User.by_name(params[:username])

    if organization.has_admin?(user)
      organization.remove_admin(user)
    else
      organization.remove_member(user)
    end

    redirect "/organization/#{params[:organization_name]}"

  end


  # Handles changing organization
  put '/organization_change/:org_name' do
    redirect '/login' unless @user

    viewer = params[:org_name]
    org_desc = params[:org_desc]
    organization = Store::Organization.by_name(viewer)
    organization.description = org_desc

    member_put = params[:member]
    member_rem = params[:rem]

    if member_put != nil
      for username in member_put
        organization.add_member(Store::User.by_name(username))
      end
    end

    if member_rem != nil
      for username in member_rem
        organization.remove_member(Store::User.by_name(username))
      end
    end

    redirect "/organization/#{viewer}"
  end

  # Handles organization's picture upload
  post '/organization/:name' do
    redirect '/login' unless @user

    viewer = Store::Organization.by_name(params[:name])
    file = params[:file_upload]
    redirect to("/organization/#{viewer}") unless file

    redirect "/error/wrong_size" if file[:tempfile].size > 400*1024

    filename = Store::Organization.id_image_to_filename(viewer, file[:filename])
    uploader = Storage::PictureUploader.with_path("/images/organizations")
    viewer.image_path = uploader.upload(file, filename)

    redirect back
  end

  post '/organization/:org_name/send_money' do
    redirect '/login' unless @user
    org_name = params[:org_name]
    org = Store::Organization.by_name(org_name)

    fail unless org.has_member?(@user)
    redirect "/error/wrong_transfer_amount" unless (!!(params[:gift_amount] =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(params[:gift_amount]) >= 0)

    amount = Integer(params[:gift_amount])

    success = org.send_money_to(@user, amount)

    redirect "/error/organization_credit_transfer_failed" unless success

    redirect back

  end
end