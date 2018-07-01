#!/usr/bin/env ruby

require 'open3'
require 'rubygems'
require 'thor'
require 'date'
require 'tempfile'
require 'pty'
require 'io/console'
require 'yaml'
require 'json'

THORFILE = (File.realdirpath(__FILE__))
WKNDIR = File.basename(Dir.pwd)
TOOL = "wkndr"

class Wkndr < Thor
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

  desc "build", ""
  def build
    build_dockerfile = ["docker", "build", "-t", WKNDIR + ":latest", "."]
    system(*build_dockerfile)
  end

  desc "provision", ""
  def provision
    dump_ca = "kubectl run dump-ca --attach=true --rm=true --image=wkndr:latest --image-pull-policy=IfNotPresent --restart=Never --quiet=true -- cat"
    system("#{dump_ca} /etc/ssl/certs/ca-certificates.crt > ca-certificates.crt")
    system("#{dump_ca} /usr/local/share/ca-certificates/ca.wkndr.crt > ca.wkndr.crt")
    system("kubectl delete configmap ca-certificates")
    system("kubectl create configmap ca-certificates --from-file=ca-certificates.crt --from-file=ca.wkndr.crt")

    deploy_wkndr_app = ["kubectl", "apply", "-f", "-"]
    options = {:stdin_data => WKNDR_RUN}
    execute_simple(:blocking, deploy_wkndr_app, options)
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

  desc "receive-pack", ""
  def receive_pack(origin)
    name_of_wkndr_pod = IO.popen("kubectl get pods -l name=wkndr-app -o name | cut -d/ -f2").read.strip

    git_push_cmd = []
    git_push_cmd += ["kubectl", "exec", name_of_wkndr_pod]
    git_push_cmd += ["-i"]
    git_push_cmd += ["--"]
    git_push_cmd += ["git", "receive-pack", "/var/tmp/workspace.git"]

    system(*git_push_cmd, options)
  end

  desc "push", ""
  def push
    system("git", "push", "-f", "wkndr", "master", "--exec=wkndr receive-pack")

#       kubectl_get_job = "kubectl get job -o yaml #{job_name}"
#       output, errors, ok = execute_simple(:blocking, kubectl_get_job)
#       first_job = YAML.load(output)
#       succeeded = first_job.dig("status", "succeeded")
#       failed = first_job.dig("status", "failed")
#       halted = (((succeeded || 0) > 0) || ((failed || 0) > 0))
# 
# status:
#   initContainerStatuses:
#   containerStatuses:
#   - containerID: docker://2759df144dc92bdffdbf469d0dd2a3f3d7aa7afb043f1e299c474f2353d62fe3
#     image: gcr.io/kaniko-project/executor:latest
#     imageID: docker-pullable://gcr.io/kaniko-project/executor@sha256:501056bf52f3a96f151ccbeb028715330d5d5aa6647e7572ce6c6c55f91ab374
#     lastState: {}
#     name: kaniko-wkndr
#     ready: false
#     restartCount: 0
#     state:
#       terminated:
#         containerID: docker://2759df144dc92bdffdbf469d0dd2a3f3d7aa7afb043f1e299c474f2353d62fe3
#         exitCode: 0
#         finishedAt: 2018-06-30T09:20:49Z
#         reason: Completed
#         startedAt: 2018-06-30T09:18:01Z

  end

KANIKO_RUN=<<-HEREDOC
---
#apiVersion: extensions/v1beta1
#apiVersion: batch/v1
#apiVersion: run-pod/v1
#apiVersion: job/v1
apiVersion: v1
#spec:
#  template:
metadata:
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
spec:
  #restartPolicy: Never
  #completions: 1
  #backoffLimit: 1
  initContainers:
    - name: git-clone
      image: wkndr:latest
      imagePullPolicy: IfNotPresent
      args:
        - git
        - clone
        - --single-branch
        - --
        - http://wkndr-app:8080/workspace.git
        - /var/tmp/git/workspace # Put it in the volume
      securityContext:
        runAsUser: 1
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
      volumeMounts:
        - mountPath: /var/tmp/git
          name: git-repo
  containers:
  - image: gcr.io/kaniko-project/executor:latest
    imagePullPolicy: IfNotPresent
    name: kaniko-wkndr
    args: [
            "--dockerfile", "Dockerfile",
            "--destination", "wkndr-app:5000/wkndr:kaniko-latest",
            "-c", "/var/tmp/git/workspace"
          ]
    volumeMounts:
    - mountPath: /var/tmp/git
      name: git-repo
    - mountPath: /kaniko/ssl/certs
      name: ca-certificates
  volumes:
  - name: git-repo
    emptyDir: {}
  - configMap:
      name: ca-certificates
    name: ca-certificates
...
HEREDOC

  desc "kaniko", ""
  def kaniko
    version = IO.popen("git rev-parse --verify HEAD").read.strip

    kaniko_run_spec = YAML.load(KANIKO_RUN)

    kaniko_run_cmd = [
                       "kubectl", "run",
                       "kaniko",
                       "--attach", "true",
                       "--image", "gcr.io/kaniko-project/executor:latest",
                       "--restart", "Never",
                       "--generator", "run-pod/v1",
                       #"--generator", "deployment/v1beta1",
                       #"--generator", "job/v1",
                       #"--dry-run",
                       #"--rm", "true",
                       "--overrides", kaniko_run_spec.to_json
                     ]

    system(*kaniko_run_cmd) || exit(1)
  end

  #desc "deploy", ""
  #def deploy
  #  #true
  #  #kubectl run \
  #  #  -it --image=trusty-rails-dev:latest \
  #  #  --image-pull-policy=IfNotPresent \
  #  #  --rm=false --attach=false --quiet=true recv -- \
  #  #  bash -c "mkdir -p /tmp/inbound && cd /tmp/inbound && git init && sleep infinity"
  #  helm_deploy = %w{helm upgrade --install wkndr ./chart}
  #  execute_simple(:blocking, build_dockerfile, options)
  #end

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

      when :async
        r, w, pid = PTY.spawn(*cmd, options)
        r.sync = true
        w.sync = true
        if $stdin.tty?
          w.winsize = [*$stdin.winsize, 0, 0]
        end
        d = Thread.new {
          begin
            done_pid, done_status = Process.waitpid2(pid)
            done_status
          rescue Errno::ECHILD => e
            nil
          end
        }
        d[:pid] = pid
        return [w, r, d, false]

    end
  end

  def execute_procfile(working_directory, procfile = "Procfile")
    time_started = Time.now
    chunk = 1024
    select_timeout = 1
    exiting = false
    exit_grace_counter = 0
    term_threshold = 3
    kill_threshold = term_threshold + 5 #NOTE: timing controls exit status
    total_kill_count = kill_threshold + 7
    select_timeout = 1.0
    needs_winsize_update = false
    trapped = false
    ljustp_padding = 0
    self_reader, self_write = IO.pipe

    trap 'INT' do
      self_write.write_nonblock("\0")

      if exiting && exit_grace_counter < kill_threshold
        exit_grace_counter += 1
      end
      exiting = true
      trapped = true
      select_timeout = 0.1
    end

    trap 'WINCH' do
      needs_winsize_update = true
    end

    Dir.chdir(working_directory || Dir.mktmpdir)

    pipeline_commands = File.readlines(procfile).collect { |line|
      process_name, process_cmd = line.split(":", 2)
      process_name.strip!
      process_cmd.strip!
      process_options = {}

      if process_name.length > ljustp_padding
        ljustp_padding = process_name.length
      end

      process_stdin, process_stdout, process_waiter = execute_simple(:async, process_cmd, process_options)
      {
        :process_name => process_name,
        :process_cmd => process_cmd,
        :process_env => {},
        :process_options => process_options,
        :process_stdin => process_stdin,
        :process_stdout => process_stdout,
        :process_waiter => process_waiter
      }
    }

    ljustp_padding += 1 #NOTE: for readability

    process_stdouts = pipeline_commands.collect { |pipeline_command| pipeline_command[:process_stdout] }
    process_stdouts += [self_reader]

    detected_exited = []

    until pipeline_commands.all? { |pipeline_command| !pipeline_command[:process_waiter].alive? }
      if exiting
        $stdout.write(" ... trying to exit gracefully, please wait #{exit_grace_counter} / #{total_kill_count}")
        $stdout.write($/)
        exit_grace_counter += 1

        pipeline_commands.each do |pipeline_command|
          process_name = pipeline_command[:process_name]
          pid = pipeline_command[:process_waiter][:pid]

          unless detected_exited.include?(pid)
            begin
              resolution = :SIGINT

              if exit_grace_counter > kill_threshold
                resolution = :SIGKILL
                Process.kill('KILL', pid)
              end

              if exit_grace_counter > term_threshold
                resolution = :SIGTERM
                Process.kill('TERM', pid)
              end

              Process.kill('INT', pid)

              $stdout.write("#{process_name} signaled... #{resolution}")
              $stdout.write($/)
            rescue Errno::EPERM, Errno::ECHILD, Errno::ESRCH => e
              detected_exited << pid
            end
          end
        end
      end

      ready_for_reading, _w, _e = IO.select(process_stdouts, nil, nil, select_timeout)

      self_reader.read_nonblock(chunk) rescue nil

      ready_for_reading && pipeline_commands.each { |pipeline_command|
        process_name = pipeline_command[:process_name]
        stdout = pipeline_command[:process_stdout]

        begin
          if ready_for_reading.include?(stdout)
            stdout_chunk = stdout.read_nonblock(chunk)
            should_newline = !stdout_chunk.end_with?($/)

            $stdout.write(process_name.ljust(ljustp_padding) + "OUT: ")
            $stdout.write(stdout_chunk)
            $stdout.write($/) if should_newline
          end
        rescue EOFError => e
          process_stdouts.delete(stdout)
        rescue IO::EAGAINWaitReadable, Errno::EIO, Errno::EAGAIN, Errno::EINTR=> e
          nil
        end
      }

      pipeline_commands.each { |pipeline_command|
        pid = pipeline_command[:process_waiter][:pid]
        process_name = pipeline_command[:process_name]
        process_waiter = pipeline_command[:process_waiter]

        unless process_waiter.alive? || detected_exited.include?(pid)
          detected_exited << pid
          process_result = process_waiter.value

          #$stdout.write("#{process_name} exited... #{process_result.success?}")
          #$stdout.write($/)
        end
      }
    end

    trap 'INT', 'DEFAULT'
    trap 'WINCH', 'DEFAULT'

    pipeline_commands.each { |pipeline_command|
      process_name = pipeline_command[:process_name]
      process_waiter = pipeline_command[:process_waiter]
      process_result = process_waiter.value

      #$stdout.write("#{process_name} trapped ... #{process_result.success?}")
      #$stdout.write($/)
    }

    # ensure nothing is left around
    Process.wait rescue Errno::ECHILD

    $stdout.write(" ... exiting")
    $stdout.write($/)
  end
end

WKNDR_RUN=<<-HEREDOC
---
apiVersion: v1
kind: Service
metadata:
  name: "wkndr-app"
spec:
  ports:
  - port: 8080
    name: apache2
    protocol: TCP
  - port: 5000
    name: docker-registry
    protocol: TCP
  selector:
    name: "wkndr-app"
...
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: wkndr-app
  labels:
    app: wkndr-app
spec:
  revisionHistoryLimit: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
  replicas: 1
  template:
    metadata:
      labels:
        name: wkndr-app
    spec:
      containers:
      - name: wkndr-app
        image: wkndr:latest
        imagePullPolicy: IfNotPresent
        resources:
          requests:
            memory: 500Mi
            cpu: 500m
          limits:
            memory: 1000Mi
            cpu: 2000m
        ports:
        - containerPort: 8080
        - containerPort: 5000
        command: ["/usr/bin/wkndr", "dev", "/usr/lib/wkndr/Procfile.init"]
HEREDOC

executing_as = File.basename($0)

case executing_as
  when "thor"

  when TOOL, "Thorfile"
    Wkndr.start(ARGV)
end
