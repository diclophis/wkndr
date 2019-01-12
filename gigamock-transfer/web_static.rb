#

require 'rack'

WebStatic = Rack::Builder.new {
  htdocs = "/var/tmp/kit1zx/release/libs/html5"
  urls = Dir.glob(File.join(htdocs, "*")).collect { |f| File.join("/", File.basename(f)) }

  Rack::Mime::MIME_TYPES.merge!({
    ".wasm" => "application/wasm"
  })

  use Rack::Static, {
    :urls => urls,
    :root => htdocs
  }

  run lambda { |env|
    [
      302,
      {
        'Location'  => '/kit1zx.html',
      },
      StringIO.new("")
    ]
  }
}.to_app
