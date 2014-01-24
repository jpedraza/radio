class Song
  COMMAND   = %{ffmpeg -f mp3 -i "%s" -vn -ac 2 -ar 44100 -ab 128000 -acodec libmp3lame -threads 4 "%s" > /dev/null 2>&1}.freeze
  DIRECTORY = "songs".freeze

  def initialize(instance, options = {})
    @url      = instance.audio_url
    @album    = instance.album.strip
    @artist   = instance.artist.strip
    @title    = instance.title.strip

    @station   = options[:radio].configuration["station"].sub(/\s+Radio$/, "")
    @directory = "#{DIRECTORY}/#{@station}"
  end

  def fetch
    if exists?
      yield
    else
      http = EventMachine::HttpRequest.new(@url).get
      http.callback do
        convert_and_remove(http.response)

        yield
      end
    end
  end

  def filename(format: "mp3")
    "#{@directory}/#{@artist} - #{@title}.#{format}"
  end

  def to_hash
    { album:    @album,
      artist:   @artist,
      duration: length_in_seconds,
      title:    @title
    }
  end

  protected

  def convert_and_remove(contents)
    original = filename(format: "aac")

    Dir.mkdir(@directory) unless Dir.exists?(@directory)

    File.open(original, "w") do |file|
      file.write(contents)
    end

    `#{sprintf(COMMAND, original, filename)}`

    File.delete(original)
  end

  def exists?
    File.exists?(filename)
  end

  def info
    @info ||= Mpg123.new(filename)
  end

  def length_in_seconds
    @length_in_seconds ||= ((info.length / info.spf) * info.tpf).to_i
  end
end
