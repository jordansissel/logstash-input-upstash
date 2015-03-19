require "securerandom"
require "sinatra/base"
class LogStash::Inputs::Upstash::App < Sinatra::Base
  set :static, true
  set :public_folder, File.join(File.dirname(__FILE__), "files")

  def initialize(callback)
    on_upload(&callback)
    super()
  end

  class Upload
    attr_reader :name
    attr_reader :mime
    attr_reader :start_time
    attr_reader :uuid

    def initialize(name, mime, fd)
      @name = name
      @mime = mime
      @fd = fd
      @uuid = SecureRandom.uuid
      @start_time = Time.now
    end

    def each(&block)
      yield @fd.read(16384) while !@fd.eof?
    end

    def duration
      Time.now - start_time
    end
  end

  def on_upload(&block)
    @on_upload = block
  end

  post "/upload" do
    name = params["file"]["filename"]
    mimetype = params["file"][:type]
    fd = params["file"][:tempfile]
    upload = Upload.new(name, mimetype, fd)
    p @on_upload
    @on_upload.call(upload) if @on_upload
  end
end
