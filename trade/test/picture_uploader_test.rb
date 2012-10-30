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
    # copy test image to tmp directory
    FileUtils::cp(File.join(File.dirname(__FILE__),"/pictures/test_picture.jpg"), Dir.tmpdir)

    uploader = Storage::PictureUploader.with_path("/images/users")
    file = {:tempfile => Tempfile.new("test_picture.jpg"), :filename => "test_picture.jpg"}

    path = uploader.upload(file, "12345", false)
    assert_equal("/images/users/12345_test_picture.jpg", path)
  end

  def test_no_file
    uploader = Storage::PictureUploader.with_path("/images/users")
    path = uploader.upload(nil, "12345")
    assert_equal("/images/no_image.gif", path)
  end
end