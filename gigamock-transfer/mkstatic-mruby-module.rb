#!/usr/bin/env ruby

require 'base64'

def mkstatic(input_static_files, name_of_export)
  input_base64 = ""
  input_static_files.each do |input_static_file|
    input_base64 += Base64.encode64(File.read(input_static_file))
  end
  return "#{name_of_export.upcase} = B64.decode(<<EOBLOB)\n" + input_base64 + "\nEOBLOB\n"
end

100.times do
  puts mkstatic(ARGV, ARGV.last.gsub(/[^a-z]/, "_"))
end
