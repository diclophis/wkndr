#

require 'yajl'
require 'date'
#require 'msgpack'

class Kube
  def pod(*args)
    sleep 0.1
    namespace, name, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time = *args
    $stdout.write([namespace, name, latest_condition, phase, container_readiness, container_states, created_at, exit_at, grace_time].to_msgpack)
    $stdout.flush
  end

  def handle_descript(description)
    @changed = true

    kind = description["kind"]
    name = description["metadata"]["name"]
    created_at = description["metadata"]["creationTimestamp"] ? DateTime.parse(description["metadata"]["creationTimestamp"]) : nil
    deleted_at = description["metadata"]["deletionTimestamp"] ? DateTime.parse(description["metadata"]["deletionTimestamp"]) : nil
    exit_at = deleted_at ? (deleted_at.to_time).to_i : nil
    grace_time = description["metadata"]["deletionGracePeriodSeconds"]
    meta_keys = description["metadata"].keys

    case kind
      when "IngressList"
        puts [kind].inspect

      when "PodList"
        puts [kind].inspect

      when "ServiceList"
        puts [kind].inspect

      when "Pod"
        latest_condition = nil
        phase = nil
        state_keys = nil
        ready = nil
        namespace = description["metadata"]["namespace"]
        status = description["status"]
        if status
          phase = status["phase"]
          if conditions = status["conditions"]
            latest_condition_in = conditions.sort_by { |a| a["lastTransitionTime"]}.last
            latest_condition = latest_condition_in["type"]
          end

          if status["containerStatuses"]
            state_keys = status["containerStatuses"].map { |f| [f["name"], f["state"].keys.first] }.to_h
            ready = status["containerStatuses"].map { |f| [f["name"], f["ready"]] }.to_h
          end
        end

        @pods ||= {}

        recalc_spec = {
          "latest_condition" => latest_condition,
          "phase" => phase,
          "ready" => ready,
          "state_keys" => state_keys,
          "created_at" => created_at.to_time.to_i,
          "exit_at" => exit_at,
          "grace_time" => grace_time
        }

        @pods[name] = recalc_spec

      when "Service"
        @services ||= {}
        spec = description["spec"]
        @services[name] = spec

      when "Ingress"
        @ingresses ||= {}
        spec = description["spec"]
        @ingresses[name] = spec

    end
  end

  def handle_event_list(event)
    items = event["items"]

    if items
      items.each do |item|
        handle_descript(item)
      end
    else
      handle_descript(event)
    end
  end

  def watch!(kubernetes_resource)
    parser = Yajl::Parser.new
    parser.on_parse_complete = method(:handle_event_list)
    io = get_yaml_producer_io(kubernetes_resource)

    @watches ||= []
    @watches << [io, parser]
  end

  def ingest!
    last_read_bit = nil
    begin
      begin
        loop do
          @changed = false
          @watches.each do |io, parser|
            last_read_bit = io
            got_read = io.read_nonblock(1024)
            parser << got_read
          end
        end
      rescue IO::EAGAINWaitReadable => idle_spin_err
        selectable_io = @watches.collect { |io, parser| io }.compact
        a,b,c = IO.select(selectable_io, [], [], 5.0)
        begin
          if a.nil? && @changed
            upstream_map = ""
            host_to_app_map = "" 
            app_to_alias_map = ""

            @ingresses && @ingresses.each { |ingress, ing_spec|
              rules = ing_spec["rules"]
              rules.each { |rule|
                host = rule["host"]
                http = rule["http"]
                paths = http["paths"]
                paths.each { |path|
                  backend = path["backend"]
                  service_name = backend["serviceName"]
                  service_port = backend["servicePort"]

                  if @services && found_service = @services[service_name] 

                    if nodePort = found_service["clusterIP"]
                    if cluster_ip = found_service["clusterIP"]
                      upstream_map += "upstream #{service_name} {\n  server #{cluster_ip}:#{service_port} fail_timeout=0;\n}\n"
                      host_to_app_map += "#{host} #{service_name};\n"
                      app_to_alias_map = "#{service_name} /usr/share/nginx/html/;\n"
                    end
                  end
                }
              }
            }

            confd_dir = ENV["MOCK_CONFD_DIR"] || "/etc/nginx/conf.d"

            File.open("#{confd_dir}/hosts_app.conf", "w+") { |f|
              f.write(upstream_map)
            }

            File.open("#{confd_dir}/hosts_app.map", "w+") { |f|
              f.write(host_to_app_map)
            }

            File.open("#{confd_dir}/hosts_app_alias.map", "w+") {|f|
              f.write(app_to_alias_map)
            }
            $stdout.write("updated vhost table\n")
            $stdout.flush
          end
          retry
        rescue Errno::EPIPE
          $stderr.write("output closed...")
        end
      end
    rescue EOFError => eof_err
      puts [last_read_bit, eof_err].inspect
      exit(1)
      #retry
    end
  rescue Interrupt => ctrlc_err
    exit(0)
  end

  def get_yaml_producer_io(kubernetes_resource)
    IO.popen("kubectl get --all-namespaces --include-uninitialized=true --watch=true --output=json #{kubernetes_resource}")
  end
end

klient = Kube.new
klient.watch!("pods")
klient.watch!("services")
klient.watch!("ingress")
klient.ingest!
