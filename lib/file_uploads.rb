require 'fastimage'
require 'tmpdir'

# NOTE: Image coordinate reference point is TOP LEFT.
# ie. 0,0 1,0 2,0
#     0,1 1,1 2,1
#     0,2 1,2 2,2

module FileUploads
  # http://sylvana.net/jpegcrop/exif_orientation.html
  TRANSFORM_OPTIONS = {
    1 => '',
    2 => '-flop',
    3 => '-rotate 180',
    4 => '-flip',
    5 => '-flip -rotate 90',
    6 => '-rotate 90',
    7 => '-flop -rotate 90',
    8 => '-rotate 270',
  }

  FILE_FORMAT = 'jpg'
  FILE_FORMAT_DOCUMENT = 'pdf'

  def handle_image_upload(uploaded, directory, desired_name=uploaded.original_filename, desired_size=nil, size_type=:max, crop_data={})
    `mkdir -p #{directory}`

    extension = File.extname(uploaded.original_filename).downcase
    if %w{.jpg .jpeg .gif .png}.include? extension
      if desired_size
        # when thumbnailing, we always convert to JPG
        unless desired_name.end_with? '.'+FILE_FORMAT
          desired_name += '.'+FILE_FORMAT
        end
      else
        unless desired_name.end_with? extension
          desired_name += extension
        end
      end

      if uploaded.size <= 20_000_000
        if enough_space_on_hd?(uploaded.size, directory)
          if desired_size
            tempfile = Tempfile.new(['raw_photo', extension])
            tempfile.binmode
            tempfile.write(uploaded.read)
            tempfile.flush

            if crop_data.blank?
              crop_option = ''
              transform_option = ''
            else
              crop_option = "-crop #{crop_data[:rightX]-crop_data[:leftX]}x#{crop_data[:bottomY]-crop_data[:topY]}#{sprintf("%+d", crop_data[:leftX])}#{sprintf("%+d", crop_data[:topY])}"
              transform_option = TRANSFORM_OPTIONS[crop_data[:orientation]]
            end

            if size_type == :max
              size = "#{desired_size[:width]}x#{desired_size[:height]}"
            elsif size_type == :min
              if crop_data.empty?
                orig_width, orig_height = FastImage.size(tempfile.path)
              else
                orig_width, orig_height = crop_data[:rightX]-crop_data[:leftX], crop_data[:bottomY]-crop_data[:topY]
              end
              orig_ratio = orig_height.to_f/orig_width.to_f
              target_ratio = desired_size[:height].to_f/desired_size[:width].to_f

              ##### We preserve the aspect ratio of the initial upload, making sure it meets the minimum requested size
              if target_ratio > orig_ratio
                size = "#{(desired_size[:height]/orig_ratio).round}x#{desired_size[:height]}"
              else
                size = "#{desired_size[:width]}x#{(desired_size[:width]*orig_ratio).round}"
              end
            else
              raise "Unknown size_type: #{size_type}"
            end

            temp_dir = Dir.tmpdir
            temppath1 = "#{temp_dir}/#{desired_name}-1"
            temppath2 = "#{temp_dir}/#{desired_name}-2"

            ##### Need to install Linux Utility 'ImageMagick' to get the 'convert' command
            ##### You'd think mogrify would work instead of using 3 different file names, but it doesn't
            ##### You'd think you could combine these steps, but you can't

            ##### Strip out metadata. Orientation is not interpreted consistently, so I'm going to rotate and mirror myself
            cmd = "convert #{tempfile.path} -strip +profile \"*\" #{temppath1}"
            if system(cmd)
              ##### Rotate/Flip the image so that it's in the expected orientation
              cmd = "convert #{temppath1} #{transform_option} #{temppath2}"
              if system(cmd)
                ##### Crop/Resize Image
                ##### Compression settings taken from https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick/
                cmd = "convert #{temppath2} #{crop_option} -filter Triangle -define filter:support=2 -resize #{size} -unsharp 0.25x0.25+8+0.065 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB #{directory}/#{desired_name}"
                puts("Running #{cmd}")
                if system(cmd) # if compression ran succesfully
                  status = :ok
                else
                  status = :thumbnail_failed
                end
              else
                status = :thumbnail_failed
              end
            else
              status = :thumbnail_failed
            end
            FileUtils.rm_f(temppath1)
            FileUtils.rm_f(temppath2)
            status
          else
            File.open(directory.to_s + '/' + desired_name, 'wb') do |file|
              file.write(uploaded.read)
            end
            :ok
          end
        else
          :not_enough_space
        end
      else
        :too_large
      end
    else
      :unknown_image_type
    end
  end

  def handle_general_upload(uploaded, directory, desired_name=uploaded.original_filename, desired_size=nil, size_type=:max, crop_data={})
    extension = File.extname(uploaded.original_filename).downcase
    if extension == '.pdf'
      return handle_pdf_upload(uploaded, directory, desired_name)
    end
    if %w".jpg .jpeg .gif .png".include? extension
      ext = '.' + desired_name.split('.').last
      desired_name = desired_name.remove(ext)
      return handle_image_upload(uploaded, directory, desired_name, desired_size, size_type, crop_data)
    end
    :unknown_file_type
  end

  def handle_pdf_upload(uploaded, directory, desired_name=uploaded.original_filename)
    extension = File.extname(uploaded.original_filename).downcase
    unless desired_name.end_with? extension
      desired_name += extension
    end

    if '.pdf' == extension
      return handle_file_upload(uploaded, directory, desired_name)
    end
    :not_pdf
  end

  def handle_file_upload(uploaded, directory, desired_name=uploaded.original_filename)
    `mkdir -p #{directory}`
    if enough_space_on_hd?(uploaded.size, directory)
      File.open(directory.to_s + '/' + desired_name, 'wb') do |file|
        file.write(uploaded.read)
      end
      :ok
    else
      :not_enough_space
    end
  end

  def output_file_format(extension)
    if extension == '.pdf'
      return FILE_FORMAT_DOCUMENT
    end
    FILE_FORMAT
  end

  def enough_space_on_hd?(needed, directory)
    df = `df #{directory}`
    free = df.lines.to_a[1].split[3].to_i * 1000
    (free - needed) > 500_000_000 # keep at least 500MB free
  end
end
