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
    #log!(:help_fu, self)

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

    #log!(:autocomp, (current_parser.candidate("--xun=b").inspect))

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

# #EQ_RE_TEST       = /^(--\w+(?:-\w+)*|-[a-z])=(.*)$/i
# #
# #a = "--cheese-bar=foo"
# ##a = "bar=foo"
# #
# ##log!(:a, a)
# #
# ##match = (a =~ (EQ_RE_TEST))
# #
# ##log!(:match, match, $1, $2)
# #
# #case a
# #  when EQ_RE_TEST
# #    log!(:match, $1, $2)
# #    log! :cheese
# #else
# #  log! :bar
# #end
# 
#     log!(:OOOOOOOOOOOOOOOOOOOOOoptions, options, @options, self)
# 
