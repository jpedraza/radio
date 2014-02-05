require "yaml"

require_relative "./song"
require_relative "./user"

class Radio
  attr_reader :player
  attr_reader :sockets
  attr_reader :song
  attr_reader :user

  def initialize
    @user    = User.new(configuration)
    @player  = Audite.new
    @sockets = []

    add_player_events
  end

  def add_socket(socket)
    @sockets << socket

    if song.nil?
      play_next
    else
      unless player.active
        player.toggle
      end

      send(song.to_hash.merge(position: position), socket)
    end

    socket.onmessage do |message|
      command(message)
    end

    socket.onclose do
      @sockets.delete(socket)

      if @sockets.empty?
        player.toggle if player.active
      end
    end
  end

  def configuration
    @configuration ||= YAML::load(File.open(".pandora"))
  end

  protected

  def add_player_events
    events = player.events
    events.on(:position_change) do |position|
      self.position = position.to_i
    end
    events.on(:complete) do
      play_next
    end
  end

  def command(method)
    case method
    when "toggle"
      player.toggle
    when "next"
      play_next
    end
  end

  def play_next
    send(event: "reset")

    player.stop_stream

    @song = Song.new(songs.shift, radio: self)
    @song.fetch do
      player.load(@song.filename)
      player.start_stream

      send(@song.to_hash)
    end
  end

  def position
    @position || player.position.to_i
  end

  def position=(position)
    return if @position == position

    send(event: "position", position: position)

    @position = position
  end

  def send(data, socket = nil)
    [socket || sockets].flatten.each do |client|
      client.send(Yajl::Encoder.encode(data))
    end
  end

  def songs
    if @songs.to_a.empty?
      @songs = next_songs
    end

    @songs
  end

  def next_songs
    station.next_songs
  rescue Pandora::APIError => exception
    if @station.nil?
      raise exception
    else
      @station = nil

      retry
    end
  end

  def station
    @station ||= user.stations.find do |station|
      station.name == configuration["station"]
    end
  end
end
