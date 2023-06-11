#!/usr/bin/env ruby

require 'base64'

def mkstatic(input_static_files, name_of_export)
  input_data = ""
  input_static_files.each do |input_static_file|
    input_data += File.read(input_static_file)
  end
  return "#{name_of_export.upcase} = B64.decode(<<EOBLOB)\n" + Base64.encode64(input_data) + "\nEOBLOB\n"
end

##?#?#?#?#?#
puts mkstatic(ARGV, ARGV.last.gsub(/[^a-z]/, "_"))
