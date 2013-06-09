class Song
  COMMAND   = %{ffmpeg -f mp3 -i "%s" -vn -ac 2 -ar 44100 -ab 128000 -acodec libmp3lame -threads 4 "%s" > /dev/null 2>&1}
  DIRECTORY = "songs"

  def initialize(instance)
    @instance = instance
    @album    = instance.album.strip
    @artist   = instance.artist.strip
    @title    = instance.title.strip
  end

  def fetch
    if exists?
      yield
    else
      http = EventMachine::HttpRequest.new(url).get
      http.callback do
        convert_and_remove(http.response)

        yield
      end
    end
  end

  def filename(format: "mp3")
    "#{DIRECTORY}/#{@artist} - #{@title}.#{format}"
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
    original  = filename(format: "aac")
    converted = filename(format: "mp3")

    Dir.mkdir(DIRECTORY) unless Dir.exists?(DIRECTORY)

    File.open(original, "w") do |file|
      file.write(contents)
    end

    `#{sprintf(COMMAND, original, converted)}`

    File.delete(original)
  end

  def exists?
    File.exists?(filename(format: "mp3"))
  end

  def info
    @info ||= Mpg123.new(filename)
  end

  def length_in_seconds
    @length_in_seconds ||= ((info.length / info.spf) * info.tpf).to_i
  end

  def url
    @instance.audio_url
  end
end
