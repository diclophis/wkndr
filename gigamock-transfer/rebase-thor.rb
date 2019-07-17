#!/usr/bin/env ruby

require 'rubygems'

module Kernel
  alias_method :original_require, :require

  def require name
    $stderr.puts(name)
    original_require name
  end
end

require 'thor'

Thor.start
