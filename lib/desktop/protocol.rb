#

class Protocol
  def ok(response_from_handler)
    "HTTP/1.1 200 OK\r\nConnection: Close\r\nContent-Length: #{resp_from_handler.length}\r\n\r\n#{resp_from_handler}"
  end

  def self.missing
    "HTTP/1.1 404 Not Found\r\nConnection: Close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 4\r\n\r\n404\n"
  end

  def self.error(exception)
    "HTTP/1.1 500 Server Error\r\nConnection: Close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: #{exception.length}\r\n\r\n#{exception}"
  end

  def self.empty
    "HTTP/1.1 200 OK\r\nConnection: Close\r\nContent-Length: 0\r\n\r\n"
  end

  def self.chunked_header(file_size, file_name)
    #header = "HTTP/1.1 200 OK\r\nContent-Length: #{file_size}\r\n#{content_type}\r\n"

    file_type_guess = file_name.split(".").last

    content_type = case file_type_guess
      when "wasm"
        "Content-Type: application/wasm\r\n"
      when "js"
        "Content-Type: text/javascript\r\n"
      when "css"
        "Content-Type: text/css\r\n"
      when "html"
        "Content-Type: text/html\r\n"
      when "txt"
        "Content-Type: text/plain\r\n"
      else
        ""
    end

    "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: #{file_size}\r\nTransfer-Coding: chunked\r\n#{content_type}\r\n"
  end
end
