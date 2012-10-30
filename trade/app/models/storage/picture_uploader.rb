# this class is responsible for all picture uploads
module Storage
  class PictureUploader
    attr_accessor :root_path

    def initialize
      self.root_path = ""
    end

    # returns an uploader object to find the picture path
    def self.with_path(path)
      uploader = PictureUploader.new
      uploader.root_path = path
      return uploader
    end

    # uploads a file and returns path to saved file
    def upload(file, identifier, copy = true)
      if file != nil
        filename = "#{identifier.to_s}_#{file[:filename]}"
        full_path = File.join("public", self.root_path)

        if copy
          FileUtils.mkdir_p(full_path)
          FileUtils::cp(file[:tempfile].path, File.join(full_path, filename))
        end

        return File.join(self.root_path, filename)
      else
        return "/images/no_image.gif"
      end
    end
  end
end