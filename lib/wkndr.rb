#

class FooOpt < OptionParser
  def candidate(word)
    list = []
    case word
    when /\A--/
      word, arg = word.split(/=/, 2)
      argpat = Completion.regexp(arg, false) if arg and !arg.empty?
      long = true
    when /\A-(!-)/
      short = true
    when /\A-/
      long = short = true
    end
    pat = Completion.regexp(word, true)
    visit(:each_option) do |opt|
      next unless Switch === opt
      opts = (long ? opt.long : []) + (short ? opt.short : [])

      opt_index = 0
      opt_each = proc { |&xlock|
        pppd = opts.at(opt_index)
        xlock.call(pppd)
        opt_index += 1
      }

      if pat
        fart = Completion.candidate(word, true, pat, &opt_each)
        opts = fart.map do |iii|
          iii[0]
        end
      end

      if /\A=/ =~ opt.arg
        opts.map! {|sw| sw + "="}
        if arg and CompletingHash === opt.pattern
          if opts = opt.pattern.candidate(arg, false, argpat)
            opts.map! do |iii|
              iii[iii.length - 1]
            end
          end
        end
      end
      list.concat(opts)
    end
    list
  end

=begin
  def getopts(*args)
    argv = Array === args.first ? args.shift : default_argv
    single_options, *long_options = *args

    result = {}

    single_options.scan(/(.)(:)?/) do |opt, val|
      if val
        result[opt] = nil
        define("-#{opt} VAL")
      else
        result[opt] = false
        define("-#{opt}")
      end
    end if single_options

    long_options.each do |arg|
      arg, desc = arg.split(';', 2)
      opt, val = arg.split(':', 2)
      if val
        result[opt] = val.empty? ? nil : val
        define("--#{opt}=#{result[opt] || "VAL"}", *[desc].compact)
      else
        result[opt] = false
        define("--#{opt}", *[desc].compact)
      end
    end

    parse_in_order(argv, proc { |x, y| result[x] = y })
    #.method(:[]=))
    result
  end
=end
end



class Wkndr
  def self.restartup(args_outer)
    log!(:restartup, args_outer)

    #class_eval do
    #  desc "startup", ""
    #  def startup(*args)
    #    server_or_client_side = self.class.to_s
    #    
    #    case server_or_client_side
    #      when "ClientSide"
    #        return client(*args)
    #      when "ServerSide"
    #        return server(*args)
    #    end
    #  end
    #  method_added :startup

    #  default_command :startup

    #  stack = start(args_outer, {})
    #  runblock!(stack) if stack && stack.is_a?(StackBlocker) #TODO: fix odd start() dispatch case
    #end
  end

  def self.server_side
    server_or_client_side = self.class.to_s
    case server_or_client_side
      when "ClientSide"
        return nil
      when "ServerSide"
        yield
    end
  end

  def self.client_side
    server_or_client_side = self.class.to_s
    case server_or_client_side
      when "ClientSide"
        yield
      when "ServerSide"
        return nil
    end
  end

  def self.mk_parser(name, *args)
    @parsers ||= {}

    options = {}

    parser = FooOpt.new do |opts|
      opts.banner = "Usage: #{name} [options]"

      #opts.on("--no-yun", "=MANDATORY", "Skip yun") do |v|
      #  options[:yun] = v
      #end

      #opts.on("--run=[TYPE]", [:other, :foop, :poof], String, "Select transfer type (other, foop, poof)") do |encoding|
      #  options[:run] = encoding
      #end

      #opts.on("--xun=[TYPE]", [:text, :binary, :auto], String, "Select transfer type (text, binary, auto)") do |encoding|
      #  options[:xun] = encoding
      #end

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end
    end

    #return parser, options
    @parsers[name] = [parser, options]
  end

  def self.desc(cmd, *args)
    mk_parser(cmd, *args)
  end

  desc "help"
  def help
    log!(:help_fu, self)

    Linenoise.multi_line = true

    # Linenoise.print_key_codes

    last_permut = nil
    current_parser = nil
    current_options = nil
    all_options = nil

    Linenoise.completion do |buf|
      #if buf == ''
      #  [Linenoise::Hint.new("deploy", 35, true)]
      #else
      #  #['hello', 'hello there']
      #  # you can also just return a String
      #  #['123', '2352\n\n3<F2>5']
      #end
      #last_permut.inspect
    end

    Linenoise.hints do |buf|
      #if buf == "" || buf == nil
      #  # this is a Struct with the folowing fields: to_str, color, bold
      #  Linenoise::Hint.new("deploy", 35, true)
      #elsif buf.start_with?("deploy")
      #  # this is a Struct with the folowing fields: to_str, color, bold
      #  Linenoise::Hint.new(" --branch=", 35, true)
      #end
      #" #{last_permut.inspect}"

      if buf.length > 0
        already_matched = []
        all_buf = buf.split(" ")

        last_cand = []

        #begin
        #puts ["ALLBUFF", all_buf.last, all_buf.inspect].inspect

        last_cand = current_parser.candidate(all_buf.last).uniq.compact

        #rescue => e
        #  puts (e.inspect)
        #  puts (e.backtrace.join("\r\n"))
        #  #$OptionParser::Switch::NoArgumentException
        #end

    #=begin
    #    (all_buf.each { |w|
    #      next if (w == "-" || w == "--")
    #      last_cand.each { |ww|
    #        if w.start_with?("--")
    #          f = w[1..2]
    #          if f == ww
    #            already_matched << f
    #          end
    #        end

    #        if ww.start_with?(w) || ww.start_with?("-" + w)
    #          already_matched << ww
    #          already_matched << w
    #        end
    #      }

    #      if last_cand.include?(w)
    #        already_matched << w
    #      end
    #    })
    #=end

        already_matched = []

        hint = "  " + (last_cand - already_matched).join(" ")

        color = 35
        #unless buf.length < 3 || all_buf.all? { |a| a.split(/-|=/).any? { |aa| all_options.include?(aa) } }
        #  hint = "ERROR" + hint
        #  color = 36
        #end
        
        Linenoise::Hint.new(hint, color, true)
      end
    end

    begin
      Linenoise::History.load('history.txt')
    rescue
    end

    #current_parser, current_options = mk_parser

    current_parser = @parsers["help"]

    log!(:autocomp, (current_parser.candidate("--xun=b").inspect))

    #all_options = current_parser.to_a.join(" ")

    while (line = linenoise("hallo> "))
      unless line.empty?
        $stdout.write "echo: #{line}\n"

        #begin
          #other_foo = current_parser.getopts(line.split(" "))
          #puts other_foo.inspect

          options = current_parser.parse(line.split(" "))
          puts current_options.inspect

          current_parser, current_options = mk_parser

          #= mk_parser
          #last_permut = mk_parser(line.split(" "))

        #rescue => e
        #  #TODO: error highlighting
        #  puts e.inspect
        #  puts e.backtrace.join("\n")
        #end

        Linenoise::History.add(line)
        Linenoise::History.save("history.txt")
      end
    end
  end
end

##
#
##NOTE: run uv loop for $stdout flushing
#$run_loop.run



# #
# 
# class Wkndr < Thor
#   def self.first_stack
#     if @stacks_to_care_about
#       @stacks_to_care_about[0]
#     end
#   end
# 
#   def self.block!
#     #log!(:runBLOCKWTFWTF, self, @stacks_to_care_about)
# 
#     if @stacks_to_care_about
#       running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }
# 
#       if running_stacks.length > 0
#         bb_ret = true
#         running_stacks.each { |rlb| bb_ret = (bb_ret && rlb.cheese) }
#         bb_ret
#       else
#         return true
#       end
#     else
#       return true
#     end
#   end
#   
#   def self.runblock!(stack)
#     self.update_with_timer!(stack)
#   end
# 
#   def self.camp(&block)
#     if @server
#       #log!(:server_side_camp, block, @server)
# 
#       #TODO: abstrace base interface
#       @server.get('/') { |ids_from_path|
#         mab = Markaby::Builder.new
#         mab.html5 "lang" => "en" do
#           mab.head do
#             mab.title "wkndr"
#             mab.style do
#               GIGAMOCK_TRANSFER_STATIC_WKNDR_CSS
#             end
#           end
#           mab.body "id" => "wkndr-body" do
#             mab.div "id" => "wkndr-terminal-container" do
#               mab.div "id" => "wkndr-terminal", "class" => "maxwh" do
#               end
#             end
#             mab.div "id" => "wkndr-graphics-container", "oncontextmenu" => "event.preventDefault()" do
#               mab.canvas "id" => "canvas", "class" => "maxwh" do
#               end
#             end
#             mab.script do
#               GIGAMOCK_TRANSFER_STATIC_WKNDR_JS
#             end
#             mab.script "async" => "async", "src" => "wkndr.js" do
#             end
#           end
#         end
#         bytes_to_return = mab.to_s
#       }
# 
#       @server.get('/robots.txt') { |ids_from_path|
#         GIGAMOCK_TRANSFER_STATIC_ROBOTS_TXT
#       }
# 
#       @server.get('/favicon.ico') { |ids_from_path|
#         GIGAMOCK_TRANSFER_STATIC_FAVICON_ICO
#       }
# 
#       block.call(@server)
#     else
#       log!(:client_side_skip)
#     end
#   end
# 
#   def self.set_stack(stack)
#     @stack = stack
#   end
# 
#   def self.set_server(server)
#     @server = server
#   end
# 
#   def self.the_server
#     @server
#   end
# 
#   def self.set_gl(gl)
#     @gl = gl
#   end
# 
#   def self.play(stack = nil, gl = nil, &block)
#     if block && !@stack && !@gl
#       return
#     end
# 
# 		if @stack && @gl && block
#       begin
#         block.call(@gl)
#       rescue => e
#         log!(:e, e, e.backtrace)
#         #@gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
#         @gl.update { |global_time, delta_time|
#           @gl.drawmode {
#             @gl.threed {
#             }
#             @gl.twod {
#               @gl.draw_fps(0, 0)
#               @gl.button(50.0, 50.0, 250.0, 20.0, "error %s" % [e]) {
#                 @gl.emit({"c" => "tty"})
#               }
#             }
#           }
#         }
#       end
# 		end
# 
#     if @gl && @stack
#       @stack.cheese
#     end
#   end
# 
#   def self.start_server(stack, *args)
#     if a_server = self.mk_server(*args)
#       stack.up(a_server)
#     end
# 
#     stack
#   end
# 
#   def self.mk_server(directory = "public")
#     unless self.to_s == "ClientSide"
#       a_server = Server.run!(directory)
#       Wkndr.set_server(a_server)
#       a_server
#     end
#   end
# 
#   def self.open_client!(stack, w, h)
#     gl = GameLoop.new
#     stack.up(gl)
# 
#     socket_stream = SocketStream.create_websocket_connection { |typed_msg|
#       gl.event(typed_msg)
#     }
# 
#     stack.did_connect {
#       socket_stream.did_connect
#     }
# 
#     stack.up(socket_stream)
# 
#     gl.emit { |msg|
#       socket_stream.write(msg)
#     }
# 
#     gl.open("wkndr", w, h, 0)
# 
#     gl.update { |global_time, delta_time|
#       gl.drawmode {
#         gl.threed {
#         }
#         gl.twod {
#           gl.draw_fps(0, 0)
#           gl.button(50.0, 50.0, 250.0, 20.0, "zzz #{global_time} #{delta_time}") {
#             gl.emit({"z" => "zzz"})
#           }
#         }
#       }
#     }
# 
#     Wkndr.set_stack(stack)
#     Wkndr.set_gl(gl)
#   end
# 
#   def self.update_with_timer!(run_loop_blocker = nil)
#     log!(:ADDING, run_loop_blocker)
# 
#     @stacks_to_care_about ||= []
#     @stacks_to_care_about << run_loop_blocker
#   end
# 
#   def self.wizbang!
#     self.show!(self.first_stack)
#   end
# 
#   def self.restartup(args_outer)
#     class_eval do
#       desc "startup", ""
#       def startup(*args)
#         server_or_client_side = self.class.to_s
#         
#         case server_or_client_side
#           when "ClientSide"
#             return client(*args)
#           when "ServerSide"
#             return server(*args)
#         end
#       end
#       method_added :startup
# 
#       default_command :startup
# 
#       stack = start(args_outer, {})
#       runblock!(stack) if stack && stack.is_a?(StackBlocker) #TODO: fix odd start() dispatch case
#     end
#   end
# end
