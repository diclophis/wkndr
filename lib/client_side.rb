#

class ClientSide < Wkndr
  #NOTE: some duplication, base-abstract class...
  def self.process_stacks!
    r = nil

    if @stacks_to_care_about
      running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }
      #Wkndr.log! [:running_stacks_length, running_stacks.length]

      if running_stacks.length > 0
        #bb_ret = true
        #running_stacks.each { |rlb| bb_ret = (bb_ret && rlb.signal) }
        #r = bb_ret

        running_stacks.each { |rlb|
          #bb_ret = (bb_ret && rlb.signal) }
          bb_ret = rlb.signal
          r = r || bb_ret
          #Wkndr.log! [:bb_ret, :true_for_exit, rlb.class, :bb_ret, bb_ret, :r, r]
        }
      else
        #Wkndr.log! [:short_circ_one]
        #return nil
      end
    else
      #Wkndr.log! [:short_circ_two]
      #return nil
    end

    #Wkndr.log! [:client_side_process_stacks, self, :should_be_true_for__exit, r]

    r
  end

  def self.startup_clientside(args)
    #Wkndr.log! [:client_side, self, Object.object_id, args]

    if args.empty?
      #Wkndr.log! [:short_circuit_client_empty]
      #NOTE: default case includes client
    elsif (args.include?("--no-client"))
      #Wkndr.log! [:short_circuit_client_aaa]
      return
    elsif (!args.include?("--and-client") && !args.include?("--no-server"))
      #Wkndr.log! [:short_circuit_client_bbb]
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

    #Wkndr.log! [:WkndrfileFetchAAAAA, wps, client_args]

    wps.each_with_index { |wp, i|
      mca = whs[i] || whs[0]

      #Wkndr.log! [:WkndrfileFetch, wp, mca]

      socket_stream = gl.connect_window!(mca[0].to_i, mca[1].to_i, wp)
      raise "unknown socket stream: TODO: fix this abstraction" unless socket_stream

      stack.up(socket_stream)
    }

    Wkndr.set_client(last_gl)

    runblock!(stack)
  end
end
