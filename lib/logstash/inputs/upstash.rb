
class LogStash::Inputs::Upstash < LogStash::Inputs::Base
  config_name "upstash"

  config :host, :validate => :string, :default => "0.0.0.0"
  config :port, :validate => :number, :default => 8080

  default :codec, "line"

  def register; end

  def run(queue)
    require "securerandom"
    require File.join(File.dirname(__FILE__), "upstash", "server")
    logger.info("Starting upstash", :host => @host, :port => @port)
    callback = proc do |upload|
      codec = @codec.clone
      upload.each do |chunk|
        codec.decode(chunk) do |event|
          event["file"] = upload.name
          event["mime"] = upload.mime
          decorate(event)
          queue << event
        end
      end
    end
    app = LogStash::Inputs::Upstash::App.new(callback)
    require "rack/handler/webrick"
    Rack::Handler::WEBrick.run(app, :Host => @host, :Port => @port)
  end
end
