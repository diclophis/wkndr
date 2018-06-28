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
  option "prepare", :type => :boolean, :default => false
  option "only-prepare", :type => :boolean, :default => false
  def dev(procfile = "Procfile")
    execute_procfile(ENV['PWD'], "Prepfile") if (options["prepare"] || options["only-prepare"])
    execute_procfile(ENV['PWD'], procfile) unless options["only-prepare"]
  end

  desc "deploy", ""
  def deploy
    #true
    #kubectl run \
    #  -it --image=trusty-rails-dev:latest \
    #  --image-pull-policy=IfNotPresent \
    #  --rm=false --attach=false --quiet=true recv -- \
    #  bash -c "mkdir -p /tmp/inbound && cd /tmp/inbound && git init && sleep infinity"
    helm_deploy = %w{helm upgrade --install wkndr ./chart}
    execute_simple(:blocking, build_dockerfile, options)
  end

  desc "changelog [CHANGELOG]", "appends changelog item to CHANGELOG.md"
  def changelog(changelog = "CHANGELOG.md")
    Dir.chdir(ENV['PWD'])

    existing_entries = File.exists?(changelog) ? File.read("CHANGELOG.md").split("\n").collect { |l| l.strip } : []

    version_delim = "#######"
    version_count = existing_entries.count { |l| l.include?(version_delim) }

    today = Date.today.to_s
    username = ENV["USER"] || "ac"
    template_args = [today, username]
    opening_line_template = "# [1.#{version_count + 1}.0] - %s - %s\n\n\n\n#{version_delim}\n" % template_args

    Tempfile.create("changelog") do |new_entry_tmp|
      new_entry_tmp.write(opening_line_template)
      new_entry_tmp.rewind

      #form = Dialog::Editbox.new do |m|
      #  m.text "Details of change"
      #  m.value new_entry_tmp.path
      #end

      #res = form.show!
      if system("vi #{new_entry_tmp.path}")
        new_entry = File.read(new_entry_tmp.path).split("\n").collect { |l| l.strip }

        if new_entry.length > 0
          new_entry << ""

          existing_entries.unshift(*new_entry)
          existing_entries << ""

          File.write(changelog, existing_entries.join("\n"))
        end
      end
    end
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

  def execute_procfile(working_directory, procfile = "Procfile")
    Dir.chdir(working_directory)

    pipeline_commands = File.readlines(procfile).collect { |line|
      process_type, process_cmd = line.split(":", 2)
      process_type.strip!
      process_cmd.strip!
      [process_type, process_cmd, nil]
    }

    puts pipeline_commands.inspect

    #execute_commands(pipeline_commands)
  end
end
