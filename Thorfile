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
require 'expect'
require 'uri'
require 'securerandom'
require 'fcntl'

#$stdin.sync = true
#$stdout.sync = true

THORFILE = (File.realdirpath(__FILE__))
WKNDR = "wkndr"
APP = File.basename(Dir.pwd)

class Wkndr < Thor
  desc "changelog [CHANGELOG]", "appends changelog item to CHANGELOG.md"
  def changelog(changelog = "CHANGELOG.md")
    Dir.chdir(ENV['PWD'])

    existing_entries = File.exists?(changelog) ? File.read(changelog).split("\n").collect { |l| l.strip } : []

    version_delim = "#######"
    version_count = existing_entries.count { |l| l.include?(version_delim) }

    today = Date.today.to_s
    username = IO.popen("git config user.name").read.strip || ENV["USER"] || "ac"
    template_args = [today, username]
    opening_line_template = "# [1.#{version_count + 1}.0] - %s - %s\n\n\n\n#{version_delim}\n" % template_args

    Tempfile.create(changelog) do |new_entry_tmp|
      new_entry_tmp.write(opening_line_template)
      new_entry_tmp.rewind

      if system("vi", new_entry_tmp.path)
        new_entry = File.read(new_entry_tmp.path).split("\n").collect { |l| l.strip }

        if new_entry.length > 0
          new_entry << ""

          existing_entries.unshift(*new_entry)
          existing_entries << ""

          File.write(changelog, existing_entries.join("\n"))
        end
      end
    end

    systemx("git", "add", changelog)
    systemx("git", "commit", "--allow-empty", "-m", "updates in #{changelog}")
  end

  desc "build", ""
  def build
    version = IO.popen("git rev-parse --verify HEAD").read.strip

    build_dockerfile = ["docker", "build", "-t", APP + ":" + version, "."]
    systemx(*build_dockerfile)

    tag_dockerfile = ["docker", "tag", APP + ":" + version, APP + ":latest"]
    systemx(*tag_dockerfile)
  end

  desc "provision", ""
  def provision
    #TODO: proper tag release support
    version = "latest"
    if (APP == WKNDR)
      version = IO.popen("git rev-parse --verify HEAD").read.strip
    end

    wkndr_run=<<-HEREDOC
---
apiVersion: v1
kind: Service
metadata:
  name: "wkndr-app"
spec:
  ports:
  - port: 8111
    name: nginx-apt-proxy
    protocol: TCP
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
apiVersion: v1
kind: Service
metadata:
  name: "wkndr-app-node"
spec:
  type: NodePort
  ports:
  - port: 5000
    nodePort: 31500
    name: docker-registry-node
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
        image: #{WKNDR}:#{version}
        imagePullPolicy: IfNotPresent
        resources:
          requests:
            memory: 500Mi
            cpu: 500m
          limits:
            memory: 1000Mi
            cpu: 2000m
        ports:
        - containerPort: 8111
        - containerPort: 8080
        - containerPort: 5000
        command: ["wkndr", "dev", "/usr/lib/wkndr/Procfile.init"]
HEREDOC

    dump_ca = "kubectl run dump-ca --attach=true --rm=true --image=#{WKNDR}:#{version} --image-pull-policy=IfNotPresent --restart=Never --quiet=true -- cat"
    systemx("#{dump_ca} /etc/ssl/certs/ca-certificates.crt > ca-certificates.crt")
    systemx("#{dump_ca} /usr/local/share/ca-certificates/ca.#{WKNDR}.crt > ca.#{WKNDR}.crt")
    system("kubectl delete configmap ca-certificates")
    systemx("kubectl create configmap ca-certificates --from-file=ca-certificates.crt --from-file=ca.#{WKNDR}.crt")

    deploy_wkndr_app = ["kubectl", "apply", "-f", "-"]
    options = {:stdin_data => wkndr_run}
    execute_simple(:blocking, deploy_wkndr_app, options)
  end

  desc "sh", ""
  def sh
    #exec("kubectl", "exec", name_of_wkndr_pod, "-i", "-t", "--", "bash")
    execute_simple(:synctty, ["kubectl", "exec", name_of_wkndr_pod, "-i", "-t", "--", "bash"], {})
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
    git_push_cmd = [
                     "kubectl", "exec", name_of_wkndr_pod,
                     "-i", #"-t",
                     "--",
                     #"bash", "--rcfile", "/root/.pushrc", "--noediting", "-i", "-c", "git receive-pack /var/tmp/#{APP}"
                     "bash", "--rcfile", "/root/.pushrc", "-c", "git receive-pack /var/tmp/#{APP}"
                   ]

    #git_push_cmd = ["ruby", "-e", "puts $stdin.tty?"]

    #git_push_cmd = ["ruby", "-e", "$stdin.binmode; puts; puts '0000'; puts $stdin.read_nonblock(1024).inspect rescue IO::EAGAINWaitReadable; $stdout.flush; puts '1' * 32; $stdout.flush; $stderr.write('*****'); $stderr.flush; puts $stdin.tty?.inspect"]

    if false || origin == "sys"
      exec(*git_push_cmd)
      #exit 1
    end

    execute_simple(:synctty, git_push_cmd, {})

    $stderr.write("EXIT2")
    exit(1)
  end

  desc "upload-pack", ""
  def upload_pack
    git_pull_cmd = [
                     "kubectl", "exec", name_of_wkndr_pod,
                     "-i", "-t",
                     "--",
                     "git", "upload-pack", "/var/tmp/#{APP}"
                   ]

    #exec(*git_pull_cmd)

    execute_simple(:synctty, git_pull_cmd, {})
  end

  desc "push", ""
  option "test", :type => :boolean, :default => false
  option "build", :type => :boolean, :default => false
  def push(branch = nil)
    branch ||= IO.popen("git rev-parse --abbrev-ref HEAD").read.strip

    git_init_cmd = [
                     "kubectl", "exec", name_of_wkndr_pod,
                     "-i",
                     "--",
                     "git", "init", "--bare", "/var/tmp/#{APP}"
                     #"git", "init", "/var/tmp/#{APP}"
                   ]

    systemx(*git_init_cmd)

    #execute_simple(:synctty, ["git", "push", "-f", "wkndr", branch, "--exec=wkndr receive-pack"], {})

    system("git", "push", "-f", "wkndr", branch, "--exec=wkndr receive-pack")

    if options["test"]
      systemx("git", "tag", "-f", "wkndr/test")
      system("git", "push", "-f", "wkndr", ":wkndr/test", "--exec=wkndr receive-pack")
      system("git", "push", "-f", "wkndr", "wkndr/test", "--exec=wkndr receive-pack")
    end

    if options["build"]
      systemx("git", "tag", "-f", "wkndr/build")
      system("git", "push", "-f", "wkndr", ":wkndr/build", "--exec=wkndr receive-pack")
      system("git", "push", "-f", "wkndr", "wkndr/build", "--exec=wkndr receive-pack")
    end
  end


  desc "kaniko", ""
  def kaniko(branch = nil)
    branch ||= IO.popen("git rev-parse --abbrev-ref HEAD").read.strip

    apt_cache_service_fetch = "kubectl get service wkndr-app -o json | jq -r '.spec.clusterIP'"
    http_proxy_service_ip = IO.popen(apt_cache_service_fetch).read.split("\n")[0]
    puts http_proxy_service_ip

    kaniko_run=<<-HEREDOC
---
apiVersion: v1
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
        - bash
        - -c
        - git clone http://wkndr-app:8080/#{APP} /var/tmp/git/#{APP} && cd /var/tmp/git/#{APP}
      securityContext:
        runAsUser: 1
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
      volumeMounts:
        - mountPath: /var/tmp/git
          name: git-repo
  containers:
  - image: gcr.io/kaniko-project/executor:81f520812c84c7ba020ff0537cf4295917f37d77
    imagePullPolicy: IfNotPresent
    name: kaniko-#{APP}
    args: [
            "--dockerfile", "Dockerfile",
            "--destination", "wkndr-app:5000/#{APP}:kaniko-latest",
            "--verbosity", "info",
            "-c", "/var/tmp/git/#{APP}"
          ]
    envs:
    - name: HTTP_PROXY_HOST
      value: #{http_proxy_service_ip}:8111
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
    kaniko_run_spec = YAML.load(kaniko_run)

    kaniko_run_cmd = [
                       "kubectl", "run",
                       "kaniko-#{APP}",
                       "--attach", "true",
                       "--image", "gcr.io/kaniko-project/executor:latest",
                       "--restart", "Never",
                       "--generator", "run-pod/v1",
                       "--rm", "true",
                       "--quiet", "true",
                       "--overrides", kaniko_run_spec.to_json
                     ]

    systemx(*kaniko_run_cmd)
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

  #TODO: --in-vivo split
  desc "repositories", ""
  def repositories
    catalog_json = fetch_from_registry("v2/_catalog")
    catalog = JSON.load(catalog_json)

    puts catalog["repositories"]
  end

  desc "tags", ""
  def tags
    catalog_json = fetch_from_registry("v2/#{APP}/tags/list")
    catalog = JSON.load(catalog_json)

    if catalog
      puts catalog["tags"]
    end
  end

  desc "test", ""
  def test(version=nil)
    apt_cache_service_fetch = "kubectl get service wkndr-app -o json | jq -r '.spec.clusterIP'"
    #puts apt_cache_service_fetch # if options["verbose"]
    http_proxy_service_ip = IO.popen(apt_cache_service_fetch).read.split("\n")[0]
    Process.wait rescue Errno::ECHILD
    puts http_proxy_service_ip

    version = IO.popen("git rev-parse --verify HEAD").read.strip #TODO
    Process.wait rescue Errno::ECHILD
    puts "you are in #{Dir.pwd} building #{version}"

    ## TODO: merge inference vs. configured steps...
    circle_yaml = YAML.load(File.read(".circleci/config.yml").gsub("{{ .Environment.CIRCLE_SHA1 }}", version).gsub("$CIRCLE_SHA1", version))

    all_job_keys = circle_yaml["jobs"].keys
    first_job = all_job_keys.first

    deps = {}
    completed = {}
    started_commands = []
    first_time_through = true

    build_job = lambda { |job_to_build|
      execute_ci(version, circle_yaml, job_to_build, http_proxy_service_ip)
    }

    find_ready_jobs = lambda {
      circle_yaml["workflows"].each do |workflow_key, workflow|
        next if workflow_key == "version"

        workflow["jobs"].each do |job_and_reqs|
          if job_and_reqs.is_a?(String)
            deps[job_and_reqs] = []
          else
            first_key = job_and_reqs.keys.first
            deps[first_key] = job_and_reqs[first_key]["requires"]
          end
        end
      end

      jobs_with_zero_req = []

      deps.each do |job, reqs|
        if reqs.all? { |req| completed[req] }
          jobs_with_zero_req << job
        end
      end

      jobs_with_zero_req.reject! { |req| completed[req] }

      if jobs_with_zero_req.compact.length > 0
        jobs_with_zero_req
      else
        nil
      end
    }

    all_cmds = []
    exiting = false

    trap 'INT' do
      exiting = true
    end

    loop do
      found_jobs = find_ready_jobs.call

      remapped = []

      found_jobs && found_jobs.each { |fjob|
        unless started_commands.include?(fjob)
          started_commands << fjob
          foo_job_tasks = build_job.call(fjob)
          #foo_job_tasks[1][0].close
          remapped << foo_job_tasks
        end
      }

      all_cmds += remapped

      process_fds = all_cmds.collect { |fjob, podn, cmds| [cmds[1], cmds[2]] }.flatten

      _r, _w, _e = IO.select(process_fds, nil, process_fds, 0.1)

      exited_this_loop = false

      all_exited = true

      all_cmds.each do |fjob, podn, cmds|
        process_waiter = cmds[3]
        exit_stdout = cmds[4]

        unless completed[fjob]
          if process_waiter.alive?
            all_exited = false
            process_waiter.join(0.1)
          else
            completed[fjob] = {}
            exit_stdout.call(cmds[1].read, cmds[2].read, process_waiter.value, false)
          end
        end
      end

      if exiting
        all_cmds.collect { |fjob, podn, cmds| systemx("kubectl delete pod/#{podn}") }

        break if all_exited
      end

      break unless found_jobs
    end

    trap 'INT', 'DEFAULT'

    Process.wait rescue Errno::ECHILD

    all_ok = all_cmds.all? { |fjob, podn, cmds| !cmds[3].alive? && cmds[3].value.success? }

    while (all_cmds.any? { |fjob, podn, cmds|
      execute_simple(:silent, ["kubectl", "get", "pod/#{podn}"], {})
    }) do
      $stdout.write(".")
      sleep 1
    end

    puts all_ok
  end

  private

  def execute_ci(version, circle_yaml, job_to_bootstrap, http_proxy_service_ip)
    build_tmp_dir = "/var/tmp" # TODO: Dir.mktmpdir ???!!!

    job = circle_yaml["jobs"][job_to_bootstrap]

    raise "unknown job #{job_to_bootstrap}" unless job

    clean_name = (APP + "-" + job_to_bootstrap + "-" + version).gsub(/[^\.a-z0-9]/, "-")[0..34]

    circle_env = {
      "CI" => "true",
      "CIRCLE_NODE_INDEX" => "0",
      "CIRCLE_NODE_TOTAL" => "1",
      "CIRCLE_SHA1" => version,
      "RACK_ENV" => "test",
      "RAILS_ENV" => "test",
      "CIRCLE_ARTIFACTS" => build_tmp_dir,
      "CIRCLE_TEST_REPORTS" => build_tmp_dir,
      "SSH_ASKPASS" => "false",
      "CIRCLE_WORKING_DIRECTORY" => "/home/app/current",
      "PATH" => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games",
      "HTTP_PROXY_HOST" => "#{http_proxy_service_ip}:8111"
    }

    if job_env = job["environment"]
      circle_env.merge!(job["environment"])
    end

    steps = job["steps"]

    #TODO: refactor image url parsing
    docker_image_url = URI.parse("http://local/#{job["docker"][0]["image"]}")
    repo = docker_image_url.host
    image_and_tag = File.basename(docker_image_url.path)

    run_name = clean_name
    run_image = image_and_tag
    build_id = SecureRandom.uuid

		build_tmp_dir = "/var/tmp"
		build_manifest_dir = File.join(build_tmp_dir, run_name, version)
		run_shell_path = File.join(build_manifest_dir, "init.sh")
		run_shell = run_shell_path

    container_specs = {
      "apiVersion" => "v1",
      "spec" => {
        #"terminationGracePeriodSeconds" => 1,
        #"securityContext" => {
        #  "fsGroup" => 20
        #},
        #"restartPolicy" => "Never",
				"initContainers" => [
          {
            "name" => "git-clone",
						"image" => "wkndr:latest",
						"imagePullPolicy" => "IfNotPresent",
						"args" => [
							"bash",
							"-c",
							"git clone http://wkndr-app:8080/#{APP} /home/app/#{APP} && ln -sf /home/app/#{APP} /home/app/current"
            ],
						"securityContext" => {
							"runAsUser" => 1,
							"allowPrivilegeEscalation" => false,
							"readOnlyRootFilesystem" => true
            },
						"volumeMounts" => [
              {
							  "mountPath" => "/home/app",
								"name" => "git-repo"
              }
            ]
          }
        ],
        "containers" => [
          {
            "name" => run_name,
            "image" => run_image,
            "imagePullPolicy" => "IfNotPresent",
            #"securityContext" => {
            #},
            "args" => [
              "bash", "-e", "-x", "-o", "pipefail", run_shell
            ],
            "volumeMounts" => [
              {
                "mountPath" => "/var/run/docker.sock",
                "name" => "dood"
              },
              {
                "mountPath" => build_manifest_dir,
                "name" => "fd-config-volume"
              },
              {
                "mountPath" => "/home/app",
                "name" => "git-repo"
              }
            ],
            "env" => circle_env.collect { |k,v| {"name" => k, "value" => v } }
          }
        ],
        "volumes" => [
          {
            "name" => "dood",
            "hostPath" => {
              "path" => "/var/run/docker.sock"
            }
          },
          {
            "name" => "fd-config-volume",
            "configMap" => {
              "name" => "fd-#{run_name}"
            }
          },
          {
            "name" => "git-repo",
            "emptyDir" => {}
          }
        ]
      }
    }

    pro_fd = StringIO.new
    flow_desc = "#{job_to_bootstrap}"

    steps.each_with_index do |step, step_index|
      if step == "checkout"
        next
      end

      if run = step["run"]
        name = run["name"]
        pro_fd.write(run["command"])

        next
      end
    end

    #pro_fd.write("\n\nwait && exit 0;")
    pro_fd.rewind

    configmap_manifest = {
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => {
        "name" => "fd-#{run_name}"
      },
      "data" => {
        "init.sh" => pro_fd.read
      }
    }

    apply_configmap = ["kubectl", "apply", "-f", "-"]
    apply_configmap_options = {:stdin_data => configmap_manifest.to_yaml}
    execute_simple(:blocking, apply_configmap, apply_configmap_options)

    ci_run_cmd = [
                   "kubectl", "run",
                   run_name,
                   "--attach", "true",
                   "--image", run_image,
                   "--restart", "Never",
                   "--generator", "run-pod/v1",
                   "--rm", "true",
                   "--quiet", "true",
                   "--overrides", container_specs.to_json
                 ]

    return job_to_bootstrap, run_name, execute_simple(:async, ci_run_cmd, {})
  rescue Interrupt => _e
    puts _e.inspect
    nil
  end

  def execute_simple(mode, cmd, options)
    exit_proc = lambda { |stdout, stderr, wait_thr_value, exit_or_not|
      $stdout.write(stdout)
      $stderr.write(stderr)
      if !wait_thr_value.success?
        $stderr.write(cmd.join(" "))
        $stderr.write($/)
        $stderr.write("FAILED!!!")
        $stderr.write($/)
        if exit_or_not
          exit 1
        end
      else
        return  stdout, stderr, wait_thr_value.success?
      end
    }

    case mode
      when :silent
        o, e, s = Open3.capture3(*cmd, options)
        return s.success?

      when :blocking
        o, e, s = Open3.capture3(*cmd, options)
        return exit_proc.call(o, e, s, true)

      when :async
        #NOTE: support tty?
        #r, w, pid = PTY.spawn(*cmd, options)
        #r.sync = true
        #w.sync = true
        #if $stdin.tty?
        #  w.winsize = [*$stdin.winsize, 0, 0]
        #end
        #d = Thread.new {
        #  begin
        #    done_pid, done_status = Process.waitpid2(pid)
        #    done_status
        #  rescue Errno::ECHILD => e
        #    nil
        #  end
        #}
        #d[:pid] = pid
        stdin, stdout, stderr, wait_thr = Open3.popen3(*cmd, options)
        return [stdin, stdout, stderr, wait_thr, exit_proc]

      when :synctty

if $stdin.tty?
  #NOTE: interesting...
  #$stdin.echo = false
  recv_stdin = $stdin
  reads_stdin = $stdin
else
  pty_io, pty_file = PTY.open
  recv_stdin = pty_file
  reads_stdin = pty_io
end

e, errw = IO.pipe
o, ow = IO.pipe

pid = spawn(*cmd, options.merge({:unsetenv_others => false, :out => ow, :in => reads_stdin, :err => errw}))

#recv_stdin.binmode
#reads_stdin.binmode
#$stdin.binmode
#$stdout.binmode
#$stderr.binmode
#o.binmode
#e.binmode
#ow.binmode
#errw.binmode

if !$stdin.tty?
  recv_stdin.raw!
end

#reads_stdin.raw!
#recv_stdin.raw!
#$stdout.raw! if $stdout.tty?
#$stderr.raw! if $stderr.tty?

#recv_stdin.sync = true
#reads_stdin.sync = true
#e.sync = true
#errw.sync = true
#o.sync = true
#ow.sync = true
#$stdout.sync = true
#$stderr.sync = true

f = Thread.new {
  begin
    done_pid, done_status = Process.waitpid2(pid)
    done_status
  rescue Errno::ECHILD => e
    nil
  end
}

done_status = nil
exiting = false
flush_count = 0
flushing = false
chunk = 1024 * 60
slowness = 0.001
stdin_eof = false

full_debug = false

fd = $stdin.fcntl(Fcntl::F_DUPFD)
stdin_io = IO.new(fd, mode: 'rb:ASCII-8BIT') #, cr_newline: true)

#stdin_io = $stdin

#stdin_io.binmode
#stdin_io.set_encoding('ASCII-8BIT')
#recv_stdin.binmode
#recv_stdin.set_encoding('ASCII-8BIT')

#Thread.abort_on_exception = true

#recv_stdin.winsize = 22, 100, 0, 0
#$stderr.write(recv_stdin.winsize.inspect)

in_t = Thread.new {
  if !stdin_io.tty?
    #last_in = IO.copy_stream(stdin_io, recv_stdin)
    while true
      begin
        readin = stdin_io.read_nonblock(chunk)
        #$stderr.write("in(#{cmd[0]}): #{readin.chars.length}")
        recv_stdin.write(readin)
        recv_stdin.flush
      rescue IO::EAGAINWaitReadable
        #$stderr.write(".")
        IO.select([stdin_io], [], [], slowness)
      rescue EOFError
        break
      end
    end
  else
    recv_stdin.eof?
  end
}

fixed = 0

out_t = Thread.new {
  #last_err = IO.copy_stream(o, $stdout)
  while true
    begin
      readout = o.read_nonblock(1)
      #if readout == "\r"
      #  #&& fixed < 4
      #  fixed += 1
      #else
        #$stderr.write("out(#{cmd[0]}): #{readout.chars.inspect}\n")
        $stdout.write(readout)
        $stdout.flush
      #end
    rescue IO::EAGAINWaitReadable
      #$stderr.write("x")
      IO.select([o], [], [], slowness)
      f.join(slowness)
    rescue EOFError
      break
    end
  end
}

err_t = Thread.new {
  last_err = IO.copy_stream(e, $stderr)
}

in_t.join
#out_t.join
#err_t.join
f.join

$stderr.write("EXIT")
$stderr.flush

#exit(f.value.success?)

#last_in = 0
#last_out = 0
#last_err = 0
#loop do
#  $stderr.write(".") if full_debug
#
#  ra, wa, er = IO.select([stdin_io, o, e].reject(&:closed?), [], [], slowness)
#
#  if ra && ra.include?(stdin_io)
#    last_in = IO.copy_stream(stdin_io, recv_stdin, 1, last_in)
#  end
#
#  #if ra && ra.include?(o)
#  #  last_out = IO.copy_stream(o, $stdout)
#  #end
#
#  if ra && ra.include?(e)
#    last_err = IO.copy_stream(e, $stderr, 1, last_err)
#  end
#
#  #if !$stdin.closed?
#  #  if $stdin.tty?
#  #  else
#  #    if ra && ra.include?(stdin_io)
#  #      #$stderr.write("C-")
#
#  #      begin
#  #        all_stdin = (stdin_io.read_nonblock(chunk))
#
#  #        if all_stdin
#  #          if !$stdin.closed? && $stdin.tty?
#  #          else
#  #            recv_stdin.write(all_stdin) if all_stdin.length > 0
#  #            #recv_stdin.flush
#  #          end
#  #        end
#  #      rescue EOFError
#  #        stdin_eof = true
#  #      rescue IO::EAGAINWaitReadable => err
#  #      end
#  #    end
#  #  end
#  #end
#
#  #$stderr.write("!") if full_debug
#
#  #if ra && ra.include?(o)
#  #  begin
#  #    all_stdout = (o.read_nonblock(chunk))
#  #    if all_stdout
#  #      $stdout.write(all_stdout) if all_stdout.length > 0
#  #      $stdout.flush
#  #    end
#  #  rescue IO::EAGAINWaitReadable => err
#  #  end
#  #end
#
#  #$stderr.write("@") if full_debug
#
#  #if ra && ra.include?(e)
#  #  begin
#  #    all_stderr = (e.read_nonblock(chunk))
#
#  #    if all_stderr
#  #      $stderr.write(all_stderr) if all_stderr.length > 0
#  #      $stderr.flush
#  #    end
#  #  rescue IO::EAGAINWaitReadable => err
#  #  end
#  #end
#
#  #$stderr.write("#") if full_debug
#  #all_stdout.gsub!("\r\n0000", "\r0000")
#  #all_stdout.gsub!("\r\n0000", "\n0000")
#  #all_stdin.gsub!("\r", "")
#  #all_stderr.gsub!("\r", "")
#  #$stderr.puts("in(#{cmd[0]}) #{all_stdin.chars.inspect}\n") if all_stdin.length > 0
#  #$stderr.puts("out(#{cmd[0]}): #{all_stdout.chars.inspect}\n") if all_stdout.length > 0
#  #$stderr.puts("err(#{cmd[0]}): #{all_stderr.chars.inspect}\n") if all_stderr.length > 0
#  #$stderr.write("clsd?:#{master.closed?}")
#  #$stderr.write("clsd?:#{slave.closed?}")
#  #$stderr.write("clsd?:#{$stdin.eof?}")
#  #$stderr.write("clsd?:#{$stdout.closed?}")
#
#  $stderr.write("^") if full_debug
#
#  begin
#    done_pid, done_status = Process.waitpid2(pid, Process::WNOHANG)
#    if done_status
#      flushing = true
#    end
#  rescue Errno::ECHILD => err
#    #$stderr.write(e.inspect)
#    flushing = true
#  end
#
#  $stderr.write("&") if full_debug
#
#  if stdin_eof && !recv_stdin.closed?
#    recv_stdin.flush
#    recv_stdin.close
#  end
#
#  if flushing
#    $stderr.write(".")
#
#    #if !recv_stdin.closed?
#    #  recv_stdin.flush
#    #end
#    
#    flush_count += 1
#
#    break if flush_count > (60.0 / slowness)
#  end
#
#  $stderr.write("*") if full_debug
#
#  if !$stdin.closed?
#    if $stdin.tty?
#    else
#      #if stdin_eof
#      #  #$stderr.write("|")
#
#      #  if $stdin.eof? && !recv_stdin.closed?
#      #    recv_stdin.flush
#      #    recv_stdin.close
#      #  end
#
#      #  begin
#      #    Process.waitpid2(pid)
#      #  rescue Errno::ECHILD
#      #    break
#      #  end
#
#      ##  $stdin.close
#      ##  reads_stdin.close
#      ##  pty_file.close
#      ##  flushing = true
#      ##  #all_stdin.write("\cd")
#      ##  #exiting = true
#      ##  #Process.kill('INT', pid) rescue Errno::ECHILD
#      #end
#    end
#  end
#
#  $stderr.write("(") if full_debug
#
#  sleep slowness
#end

#if $stdin.tty?
#  $stdin.echo = true
#end

exit((done_status && done_status.success?) || false)

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

      process_stdin, process_stdout, process_stderr, process_waiter = execute_simple(:async, process_cmd, process_options)
      {
        :process_name => process_name,
        :process_cmd => process_cmd,
        :process_env => {},
        :process_options => process_options,
        :process_stdin => process_stdin,
        :process_stdout => process_stdout,
        :process_stderr => process_stderr,
        :process_waiter => process_waiter
      }
    }

    ljustp_padding += 1 #NOTE: for readability

    process_stdouts = pipeline_commands.collect { |pipeline_command| pipeline_command[:process_stdout] }
    process_stdouts += [self_reader]

    process_stderrs = pipeline_commands.collect { |pipeline_command| pipeline_command[:process_stderr] }
    process_stderrs += [self_reader]

    detected_exited = []

    until pipeline_commands.all? { |pipeline_command| !pipeline_command[:process_waiter].alive? }
      if exiting
        exit_grace_counter += 1

        $stdout.write(" ... trying to exit gracefully, please wait #{exit_grace_counter} / #{total_kill_count}")
        $stdout.write($/)

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

              #$stdout.write("#{process_name} signaled... #{resolution}")
              #$stdout.write($/)
            rescue Errno::EPERM, Errno::ECHILD, Errno::ESRCH => e
              detected_exited << pid
            end
          end
        end
      end

      ready_for_reading, _w, _e = IO.select(process_stdouts + process_stderrs, nil, nil, select_timeout)
      $stdout.flush

      self_reader.read_nonblock(chunk) rescue nil

      ready_for_reading && pipeline_commands.each { |pipeline_command|
        process_name = pipeline_command[:process_name]
        stdout = pipeline_command[:process_stdout]
        stderr = pipeline_command[:process_stderr]

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

        begin
          if ready_for_reading.include?(stderr)
            stderr_chunk = stderr.read_nonblock(chunk)
            should_newline = !stderr_chunk.end_with?($/)

            $stdout.write(process_name.ljust(ljustp_padding) + "ERR: ")
            $stdout.write(stderr_chunk)
            $stdout.write($/) if should_newline
          end
        rescue EOFError => e
          process_stderrs.delete(stderr)
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

          $stdout.write("#{process_name} exited... #{process_result.success?}")
          $stdout.write($/)
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

  def systemx(*args)
    unless system(*args)
      puts "!!!!!! #{args} failed !!!!!"
      exit(1)
    end
  end

  def name_of_wkndr_pod
    IO.popen("kubectl get pods -l name=wkndr-app -o name | cut -d/ -f2").read.strip
  end

  def fetch_from_registry(path)
    ssl_cert_file = "ca.wkndr.crt"

    kubectl_port_forward_cmd = [
                                 "kubectl",
                                 "port-forward",
                                 name_of_wkndr_pod,
                                 "5000"
                               ]

    options = {}
    process_stdin, process_stdout, process_stderr, process_waiter = execute_simple(:async, kubectl_port_forward_cmd, options)

    process_stdout.expect("-> 5000")

    curl_cmd = [
                         "curl",
                         "-s",
                         "--cacert",
                         ssl_cert_file,
                         "--resolve",
                         "wkndr-app:5000:127.0.0.1",
                         "https://wkndr-app:5000/#{path}"
                       ]

    result = IO.popen(curl_cmd).read.strip
    process_waiter.kill
    process_waiter.join
    result
  end
end

executing_as = File.basename($0)

case executing_as
  when "thor"

  when WKNDR, "Thorfile"
    Wkndr.start(ARGV)
end
