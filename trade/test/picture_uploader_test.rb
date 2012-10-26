require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../app/models/storage/picture_uploader'
require_relative '../app/models/store/user'
require_relative '../app/models/security/string_checker'

class Picture_Uploader_Test < Test::Unit::TestCase

  def test_initially_path
    user = Store::User.named("X")
    assert_equal(user.image_path, "/images/no_image.gif", "wrong path")
  end

  def test_added_path
    user = Store::User.named("X")
    root = "/images/users"
    pic = Storage::PictureUploader.with_path(root)
    file = "mh.jpg" ### should be a hash which is used in 'edit_profile.haml'
    filename = Store::User.id_image_to_filename(user.name, file)
    uploader = pic
                    #user.image_path = uploader.upload(file, filename)

    assert_equal(filename, "X_mh.jpg")
    #assert_equal(user.image_path, "/images/users/X_mh.jpg")

  end

end