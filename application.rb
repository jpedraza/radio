require "bundler/setup"

Bundler.require

require "./lib/radio"

EventMachine.run do
  class Application < Sinatra::Base
    get "/" do
      File.open("public/index.html")
    end
  end

  Thin::Logging.silent = true
  Thin::Server.start(Application, "0.0.0.0", 4567)

  $radio = Radio.new

  EventMachine::WebSocket.start(host: "0.0.0.0", port: 8080) do |socket|
    socket.onopen do
      $radio.add_socket(socket)
    end
  end
end
