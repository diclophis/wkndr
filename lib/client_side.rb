#

class ClientSide < Wkndr
  #NOTE: some duplication, base-abstract class...
  def self.process_stacks!
    if @stacks_to_care_about
      running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }
      if running_stacks.length > 0
        bb_ret = true
        running_stacks.each { |rlb| bb_ret = (bb_ret && rlb.signal) }
        bb_ret
      else
        return true
      end
    else
      return true
    end
  end

  def self.startup_clientside(args)
    log!(:client_side, self, Object.object_id, args)

    if args.empty?
      #NOTE: default case includes client
    elsif (args.include?("--no-client"))
      log!(:short_circuit_client_aaa)
      return
    elsif (!args.include?("--and-client") && !args.include?("--no-server"))
      log!(:short_circuit_client_bbb)
      return
    end

    client_args = args.find_all { |arg| arg[0,9] == "--client=" }

    party_args = args.find_all { |arg| arg[0,8] == "--party=" }

    dw = 640
    dh = 480

    whs = []
    wps = []

    if client_args.empty?
      whs << [dw, dh]
    else
      client_args.each { |client_arg|
        a,b = client_arg.split("=")
        w, h = (b.split("x"))
        whs << [w, h]
      }
    end

    stack = StackBlocker.new

    if party_args.empty?
      wps << "Wkndrfile"
    else
      party_args.each { |party_arg|
        a,b = party_arg.split("=")
        wps << b
      }
    end

    last_gl = nil
    last_gl = gl = GameLoop.new
    stack.up(gl)

    log!(:WkndrfileFetchAAAAA, wps, client_args)

    wps.each_with_index { |wp, i|
      mca = whs[i] || whs[0]

      log!(:WkndrfileFetch, wp, mca)

      socket_stream = gl.connect_window!(mca[0].to_i, mca[1].to_i, wp)
      raise "unknown socket stream: TODO: fix this abstraction" unless socket_stream

      stack.up(socket_stream)
    }

    Wkndr.set_client(last_gl)

    runblock!(stack)
  end
end
