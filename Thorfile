#!/usr/bin/env ruby

require 'open3'

class Wkndr < Thor
  desc "provision", ""
  def provision
    dockerfile = "Dockerfile"
    build_dockerfile = %w{docker build -t wkndr:latest -}
    options = {:stdin_data => File.read(dockerfile)}
    execute_simple(:blocking, build_dockerfile, options)
  end

  desc "continous", ""
  def continous
    sleep
  end

  desc "dev", ""
  def dev
    # parse Procfile
  end

  private

  def execute_simple(mode, cmd, options)
    exit_proc = lambda { |stdout, stderr, wait_thr_value, exit_or_not|
      $stdout.write(stdout)
      $stderr.write(stderr)
      if !wait_thr_value.success? && exit_or_not
        $stderr.write(cmd.inspect + "\n")
        $stderr.write("FAILED!!!")
        exit 1
      else
        return  stdout, stderr, wait_thr_value.success?
      end
    }

    case mode
      when :blocking
        o, e, s = Open3.capture3(*cmd, options)
        return exit_proc.call(o, e, s, true)
    end
  end
end
