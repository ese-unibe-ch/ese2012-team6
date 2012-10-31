# this class is responsible for all picture uploads
module Storage
  # provides services for uploading images
  class PictureUploader
    attr_accessor :path, :root

    def initialize
      self.root = ""
      self.path = ""
    end

    # returns an uploader object to find the picture path
    def self.with_path(root, path)
      uploader = PictureUploader.new
      uploader.root = root
      uploader.path = path
      uploader
    end

    # uploads a file and returns path to saved file, disable copy only for testing
    def upload(file, identifier, copy = true)
      return "/images/no_image.gif" if file.nil?

      filename = "#{identifier.to_s}_#{file[:filename]}"
      full_path = File.join(self.root, self.path)

      if copy
        FileUtils.mkdir_p(full_path)
        FileUtils::cp(file[:tempfile].path, File.join(full_path, filename))
      end

      File.join(self.path, filename)
    end
  end
end