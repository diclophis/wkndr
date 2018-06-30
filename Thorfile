#!/usr/bin/env ruby

require 'open3'
require 'rubygems'
require 'thor'
require 'date'
require 'tempfile'

#ln -fs $(pwd)/Thorfile /usr/local/bin/wkndr

THORFILE = (File.realdirpath(__FILE__))
TOOL = File.basename(Dir.pwd)

#git archive --format=tar --prefix=junk/ HEAD > /var/tmp/version.tar
# run wkndr:latest init
# exec

class Wkndr < Thor
  desc "provision", ""
  def provision
    #dockerfile = "Dockerfile"
    build_dockerfile = ["docker", "build", "-t", TOOL + ":latest", "."]
    options = {} #:stdin_data => File.read(dockerfile)}
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

  desc "push", ""
  def push(origin = nil)
    if origin
      name_of_wkndr_pod = IO.popen("kubectl get pods -l name=wkndr-app -o name | cut -d/ -f2").read.strip

      git_push_cmd = []
      git_push_cmd += ["kubectl", "exec", name_of_wkndr_pod]
      git_push_cmd += ["-i"]
      git_push_cmd += ["--"]
      git_push_cmd += ["git", "receive-pack", "/var/tmp/workspace.git"]

      #options = {:close_others => true, :stdin_data => "cheese"}

      system(*git_push_cmd, options)
    else
      system("git", "push", "wkndr", "master", "--exec=wkndr push")
    end
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
        $stderr.write(cmd.join(" "))
        $stderr.write($/)
        $stderr.write("FAILED!!!")
        $stderr.write($/)
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

executing_as = File.basename($0)

case executing_as
  when "thor"
    # default mode

  when TOOL, "Thorfile"
    Wkndr.start(ARGV)
end
