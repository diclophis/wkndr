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

#require_relative './lib/termios'

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

  desc "checkout", ""
  def checkout(repo, version, destination)
    systemx("mkdir", "-p", destination)

    #TODO: implement locking as an option
    wkndr_lock = "#{File.dirname(destination)}/.wkndr.lock"

    File.open(wkndr_lock, File::RDWR|File::CREAT, 0644) { |f|
      f.flock(File::LOCK_EX)
      if Dir.chdir(destination)
        if system("git", "status")
        else
          systemx("git", "init")
        end

        system("git", "remote", "add", "origin", repo)
        systemx("git","fetch", "origin")

        #TODO: implement caching option/flag
        #systemx("git", "clean", "-f", "-d", "-x")
        systemx("git", "checkout", "-f", version)
      end
    }
  end

  desc "build", ""
  option "run", :type => :boolean, :default => false
  option "cache", :type => :boolean, :default => true
  def build
    version = IO.popen("git rev-parse --verify HEAD").read.strip

    build_dockerfile = ["docker", "build", options["cache"] ? nil : "--no-cache", "-t", APP + ":" + version, "."].compact
    systemx(*build_dockerfile)

    tag_dockerfile = ["docker", "tag", APP + ":" + version, APP + ":latest"]
    systemx(*tag_dockerfile)

    tag_dockerfile = ["docker", "tag", APP + ":" + version, APP + ":git-latest"]
    systemx(*tag_dockerfile)

    tag_dockerfile = ["docker", "tag", APP + ":" + version, "localhost/" + APP + ":git-latest"]
    systemx(*tag_dockerfile)

    if options["run"]
      #run_dockerfile = ["docker", "run", "--rm", "-it", "-p", "8000:8000", APP + ":" + version]
      #exec(*run_dockerfile)

    #apt_cache_service_fetch = "kubectl get service wkndr-app -o json | jq -r '.spec.clusterIP'"
    #http_proxy_service_ip = IO.popen(apt_cache_service_fetch).read.split("\n")[0]
    #puts http_proxy_service_ip

      run_dockerfile = ["kubectl", "run", "--rm=true", APP, "--attach=true", "--expose", "--port", "8000", "--image", APP + ":" + version, "--image-pull-policy=IfNotPresent"]
      exec(*run_dockerfile)
    end
  end

  desc "reclaim", ""
  def reclaim
    docker_prune = ["docker", "system", "prune", "-a", "--volumes"]
    exec(*docker_prune)
  end

  desc "init", ""
  option "re-init", :type => :boolean, :default => false
  def init
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
      annotations:
        "ops.v2.rutty/bash": bash
    spec:
      volumes:
        - name: tmp
          hostPath:
            path: /var/tmp/wkndr-scratch-dir
      containers:
      - name: wkndr-app
        securityContext:
          privileged: true
        volumeMounts:
          - mountPath: /var/tmp
            name: tmp
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
        command: ["wkndr", "dev", "/var/lib/wkndr/Procfile.init"]
        env:
        #- name: GIT_TRACE_PACKET
        #  value: "/var/log/git.trace"
        #- name: GIT_FLUSH
        #  value: "1"
...
HEREDOC

    dump_ca = "kubectl run dump-ca --attach=true --rm=true --image=#{WKNDR}:#{version} --image-pull-policy=IfNotPresent --restart=Never --quiet=true -- cat"
    systemx("#{dump_ca} /etc/ssl/certs/ca-certificates.crt > /var/tmp/wkndr-ca-certificates.crt")
    systemx("#{dump_ca} /usr/local/share/ca-certificates/ca.#{WKNDR}.crt > /var/tmp/wkndr.ca.#{WKNDR}.crt")
    system("kubectl delete configmap ca-certificates")
    systemx("kubectl create configmap ca-certificates --from-file=/var/tmp/wkndr-ca-certificates.crt --from-file=/var/tmp/wkndr.ca.#{WKNDR}.crt")

    if options["re-init"]
      deploy_wkndr_app = ["kubectl", "delete", "-f", "-"]
      options = {:stdin_data => wkndr_run}
      execute_simple(:blocking, deploy_wkndr_app, options)
    end

    deploy_wkndr_app = ["kubectl", "apply", "-f", "-"]
    options = {:stdin_data => wkndr_run}
    execute_simple(:blocking, deploy_wkndr_app, options)
  end

  desc "sh", ""
  def sh
    exec(*["kubectl", "exec", name_of_wkndr_pod, "-i", $stdin.tty? ? "-t" : nil, "--", "bash"].compact)
  end

  desc "logs", ""
  def logs
    exec(*["kubectl", "logs", name_of_wkndr_pod, "-f"].compact)
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

  desc "rcp", ""
  def rcp(app, origin)
    #if $stdin.tty?
    #  oldt = Termios.tcgetattr($stdin)
    #  newt = oldt.dup
    #  newt.oflag &= ~Termios::ONLCR
    #  #newt.oflag &= ~Termios::OPOST
    #  Termios.tcsetattr($stdin, Termios::TCSANOW, newt)
    #end

    #$stdin.sync = true
    #$stdout.sync = true
    #$stderr.sync = true

    cmd = ["git", "receive-pack", "/var/tmp/#{app}"]

    #execute_simple(:synctty, cmd, {})
    exec(*cmd)
  end

  desc "receive-pack", ""
  def receive_pack(origin)
    git_push_cmd = [
                     "kubectl", "exec", name_of_wkndr_pod,
                     "-i",
                     "--",
                     "wkndr", "rcp", APP, origin 
                   ]

    #execute_simple(:synctty, git_push_cmd, {})
    exec(*git_push_cmd)
  end

  desc "upload-pack", ""
  def upload_pack
    git_pull_cmd = [
                     "kubectl", "exec", name_of_wkndr_pod,
                     "-i",
                     "--",
                     "git", "upload-pack", "/var/tmp/#{APP}"
                   ]

    #execute_simple(:synctty, git_pull_cmd, {})
    exec(*git_pull_cmd)
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
                   ]

    systemx(*git_init_cmd)

    systemx("git", "push", "-f", "wkndr", branch, "--exec=wkndr receive-pack")

    if options["test"]
      systemx("git", "tag", "-f", "wkndr/test")
      system("git", "push", "-f", "wkndr", ":wkndr/test", "--exec=wkndr receive-pack")
      exec("git", "push", "-f", "wkndr", "wkndr/test", "--exec=wkndr receive-pack")
    end

    if options["build"]
      systemx("git", "tag", "-f", "wkndr/build")
      system("git", "push", "-f", "wkndr", ":wkndr/build", "--exec=wkndr receive-pack")
      exec("git", "push", "-f", "wkndr", "wkndr/build", "--exec=wkndr receive-pack")
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
        - wkndr
        - checkout
        - http://wkndr-app:8080/#{APP} 
        - master
        - /home/app/current
      securityContext:
        runAsUser: 1
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
      volumeMounts:
        - mountPath: /var/tmp/git
          name: git-repo
  containers:
  - image: gcr.io/kaniko-project/executor:5f9fb2cb8d55003b2da8f406e22a4705b08d471e
    imagePullPolicy: IfNotPresent
    name: kaniko-#{APP}
    args: [
            "--dockerfile", "Dockerfile",
            "--destination", "wkndr-app:5000/#{APP}:kaniko-latest",
            "--verbosity", "info",
            "-c", "/var/tmp/git/#{APP}"
          ]
    env:
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

  #TODO: install via helm???
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

  desc "latest", ""
  def latest
    system("docker images | grep latest | awk -e '{ print $1 \":\" $2 }'")
  end

  desc "test", ""
  def test(just_this_job=nil, version=nil)
    #system("echo cheese")
    #system("mkdir -p /var/tmp/wkndr-scratch-dir/#{APP}/current && chmod -Rv 777 /var/tmp/wkndr-scratch-dir")
    #system("mkdir -p /var/tmp/wkndr-git-dir/#{APP} && chmod -Rv 777 /var/tmp/wkndr-git-dir")

    apt_cache_service_fetch = "kubectl get service wkndr-app -o json | jq -r '.spec.clusterIP'"
    #puts apt_cache_service_fetch # if options["verbose"]
    http_proxy_service_ip = IO.popen(apt_cache_service_fetch).read.split("\n")[0]
    Process.wait rescue Errno::ECHILD
    puts http_proxy_service_ip

    version = IO.popen("git rev-parse --verify HEAD").read.strip #TODO
    Process.wait rescue Errno::ECHILD
    puts "you are in #{Dir.pwd} building #{version}"

    config_yml = ".circleci/config.yml"
    ## TODO: merge inference vs. configured steps...
    circle_yaml = YAML.load(File.read(config_yml).gsub("{{ .Environment.CIRCLE_SHA1 }}", version).gsub("$CIRCLE_SHA1", version))

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
            if job_and_reqs[first_key]
              deps[first_key] = job_and_reqs[first_key]["requires"]
            end
          end
        end
      end

      jobs_with_zero_req = []

      deps.each do |job, reqs|
        if !reqs || reqs.all? { |req| completed[req] }
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
        count_of_started = started_commands.length
        count_of_finished = completed.length
        max_queued = count_of_started - count_of_finished

        if max_queued < 6
          unless started_commands.include?(fjob)
            if !just_this_job || (just_this_job && just_this_job == fjob)
              started_commands << fjob
              foo_job_tasks = build_job.call(fjob)
              remapped << foo_job_tasks
            else
              completed[fjob] = {}
            end
          end
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
            chunk = 65432
            begin
              output = cmds[1].read_nonblock(chunk)
              $stdout.write(output)
            rescue IO::EAGAINWaitReadable, Errno::EIO, Errno::EAGAIN, Errno::EINTR => err
            rescue EOFError => err
            end
            process_waiter.join(0.1)
          else
            completed[fjob] = {}
            $stderr.write(">>>>>>>>>> (#{config_yml}) #{fjob} finished\n")
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
    job = circle_yaml["jobs"][job_to_bootstrap]

    raise "unknown job #{job_to_bootstrap}" unless job

    clean_name = (APP + "-" + job_to_bootstrap).gsub(/[^\.a-z0-9]/, "-")[0..34]

    circle_env = {
      "CI" => "true",
      "CIRCLE_NODE_INDEX" => "0",
      "CIRCLE_NODE_TOTAL" => "1",
      "CIRCLE_SHA1" => version,
      "RACK_ENV" => "test",
      "RAILS_ENV" => "test",
      "CIRCLE_ARTIFACTS" => "/var/tmp/artifacts",
      "CIRCLE_TEST_REPORTS" => "/var/tmp/reports",
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
    unless job["docker"]
      $stderr.puts "req'd docker key missing" 
      exit 1
    end

    docker_image_url = URI.parse("http://local/#{job["docker"][0]["image"]}")
    repo = docker_image_url.host
    image_and_tag = File.basename(docker_image_url.path)

    run_name = clean_name
    run_image = image_and_tag
    build_id = SecureRandom.uuid

    build_tmp_dir = "/var/tmp/wkndr-scratch-dir"
    build_manifest_dir = File.join(build_tmp_dir, run_name, version)
    run_shell_path = File.join(build_manifest_dir, "init.sh")
    run_shell = run_shell_path

    container_specs = {
      "apiVersion" => "v1",
      "spec" => {
        "securityContext" => {
          #"fsGroup" => 20
          "privileged" => true
        },
        #"restartPolicy" => "Never",
        #"annotations": {
        #  "labels"
        #},
        "initContainers" => [
          {
            "terminationGracePeriodSeconds" => 5,
            "name" => "git-clone",
            "image" => "wkndr:latest",
            "imagePullPolicy" => "IfNotPresent",
            "args" => [
              "wkndr", "checkout", "http://wkndr-app:8080/#{APP}", version, "/home/app/current"
            ],
            "env" => { "GIT_DISCOVERY_ACROSS_FILESYSTEM" => "true" }.collect { |k,v| {"name" => k, "value" => v } },
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
            "terminationGracePeriodSeconds" => 5,
            "name" => run_name,
            "image" => run_image,
            "imagePullPolicy" => "IfNotPresent",
            "workingDir" => job["working_directory"],
            #"securityContext" => {
            #},
            "args" => [
              "bash", "-e", "-o", "pipefail", run_shell
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
              },
              {
                "mountPath" => "/home/app/.ssh",
                "name" => "ssh-key"
              },
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
              "name" => "fd-#{run_name}-#{version}"
            }
          },
          {
            "name" => "git-repo",
            #"emptyDir" => {}
            "hostPath" => {
              "path" => "/var/tmp/wkndr-git-dir/#{APP}"
            }
          },
          {
            "name" => "ssh-key",
            "hostPath" => {
              "path" => "#{ENV['HOME']}/.ssh"
            }
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

    pro_fd.rewind

    configmap_manifest = {
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => {
        "name" => "fd-#{run_name}-#{version}"
      },
      "data" => {
        "init.sh" => pro_fd.read
      }
    }

    apply_configmap = ["kubectl", "apply", "-f", "-"]
    apply_configmap_options = {:stdin_data => configmap_manifest.to_yaml}
    execute_simple(:silentx, apply_configmap, apply_configmap_options)

    execute_simple(:silent, ["kubectl", "delete", "pod/#{run_name}", "--grace-period=5"], {})

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
    exit_proc = lambda { |stdout, stderr, wait_thr_value, exit_or_not, silent=false|
      $stdout.write(stdout) unless silent
      if !wait_thr_value.success?
        $stderr.write(stderr)
        $stderr.write(cmd.map { |c| ["'", c, "'"].join }.join(" "))
        $stderr.write($/)
        $stderr.write("FAILED!!!")
        $stderr.write($/)
        exit 1
        if exit_or_not
          exit 1
        end
      else
        return stdout, stderr, wait_thr_value.success?
      end
    }

    case mode
      when :silent
        o, e, s = Open3.capture3(*cmd, options)
        return s.success?

      when :silentx
        o, e, s = Open3.capture3(*cmd, options)
        s.success?
        return exit_proc.call(o, e, s, true, true)

      when :blocking
        o, e, s = Open3.capture3(*cmd, options)
        return exit_proc.call(o, e, s, true)

      when :async
        stdin, stdout, stderr, wait_thr = Open3.popen3(*cmd, options)
        stdout.sync
        return [stdin, stdout, stderr, wait_thr, exit_proc]

    end
  end

  def execute_procfile(working_directory, procfile = "Procfile")
    time_started = Time.now
    chunk = 1024
    exiting = false
    exit_grace_counter = 0
    term_threshold = 3
    kill_threshold = term_threshold + 5 #NOTE: timing controls exit status
    total_kill_count = kill_threshold + 7
    select_timeout = 10.0
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
      select_timeout = 1.0
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
            #should_newline = !stdout_chunk.end_with?($/)
            #if should_newline

            stdout_chunk.split($/).each do |sc|
              $stdout.write(process_name.ljust(ljustp_padding) + "OUT: ")
              $stdout.write(sc)
              $stdout.write($/)
            end
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
