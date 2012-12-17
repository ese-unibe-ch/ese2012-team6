require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative '../../app/models/helpers/storage/picture_uploader'
require_relative '../../app/models/store/user'
require_relative '../../app/models/helpers/security/string_checker'

class PictureUploaderTests < Test::Unit::TestCase
  UPLOAD_PATH = File.dirname(__FILE__)

  # uploading a pic must change the path
  def test_upload_picture
    # copy test image to tmp directory
    FileUtils::cp(File.join(File.dirname(__FILE__), "/pictures/test_picture.jpg"), Dir.tmpdir)

    # create file to upload
    file = {:tempfile => Tempfile.new("test_picture.jpg"), :filename => "test_picture.jpg"}

    uploader = Storage::PictureUploader.with_path(UPLOAD_PATH, "/images/users")
    path = uploader.upload(file, "12345", false) # don't really copy image to folder

    assert_equal("/images/users/12345_test_picture.jpg", path)
  end

  # when no pic is uploaded then the path is still no_image
  def test_no_file
    uploader = Storage::PictureUploader.with_path(UPLOAD_PATH, "/images/users")
    path = uploader.upload(nil, "12345")

    assert_equal("/images/no_image.gif", path)
  end
end