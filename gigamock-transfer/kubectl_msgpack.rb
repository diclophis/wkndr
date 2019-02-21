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

        #pod(namespace, name, latest_condition, phase, ready, state_keys, created_at.to_time.to_i, exit_at, grace_time)
        puts [kind, namespace, name, latest_condition, phase, ready, state_keys, created_at.to_time.to_i, exit_at, grace_time].inspect

      when "Service"
        puts [kind, namespace, name].inspect

      when "Ingress"
        puts [kind, namespace, name].inspect

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

          @watches.each do |io, parser|
            last_read_bit = io
            got_read = io.read_nonblock(1024)
            parser << got_read
          end

        end

      rescue IO::EAGAINWaitReadable => idle_spin_err
        selectable_io = @watches.collect { |io, parser| io unless io.closed? }.compact
        a,b,c = IO.select(selectable_io, nil, nil, 1.0)
        begin
          #$stdout.write(nil.to_msgpack)
          $stdout.flush
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
