#

class Base < Thor
  def client_and_server
    stack = StackBlocker.new
    stack.up client
    stack.up server
    stack
  end

  desc "server", ""
  def server
    if File.exists?("public")
      Server.run!(File.realpath("public"))
    end
  end

  desc "client", ""
  def client
    #TODO: refactor multi loop
    window("window", 512, 512, 60) { |window, gl|
      log! :in_opened_window, window, gl

      gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
      cube = Cube.new(1.0, 1.0, 1.0, 5.0)

      gl.play { |global_time, delta_time|
        gl.drawmode {
          gl.threed {
            gl.draw_grid(10, 10.0)
            cube.draw(true)
          }

          gl.twod {
            gl.button(0.0, 0.0, 250.0, 20.0, "start #{global_time}") {
              log! :click
            }
          }
        }
      }
    }
  end

  def self.start(args)
    log!(:START, args)

    running = true
    Signal.trap(:INT) { |signo|
      running = false
    }

    if args.empty?
      args = ["client_and_server"]
    end

    if running && run_loop_blocker = super(args)
      log!(:rl, run_loop_blocker)

      #idle_updater = UV::Timer.new
      #idle_updater.start(0, 1) {
      #}

      exit_counter = 0

      #TODO: server FPS
      fps = 30.0
      tick_interval_ms = ((1.0/60.0)*1000.0)
      ticks = 0
      timer = UV::Timer.new
      timer.start(tick_interval_ms, tick_interval_ms) { |x|
        ticks += 1
        if running && run_loop_blocker.running
          if ((ticks) % 100) == 0
            log!(:idle, ticks)
          end

          run_loop_blocker.update
        else
          if exit_counter > 5
            log!(:shutdown, ticks, exit_counter)

            run_loop_blocker.shutdown
            timer.stop
          end

          all_halting = run_loop_blocker.halt!
          log!(:all_halting, ticks, exit_counter, all_halting)


          exit_counter += 1
        end
      }

      show! run_loop_blocker

      UV.run
    end
    #log!(:END)
  end

  desc "serve [DIRECTORY]", "services given directory over http"
  def serve(directory)
    Server.run!(directory)
  end

  desc "changelog [CHANGELOG]", "appends changelog item to CHANGELOG.md"
  def changelog(changelog = "CHANGELOG.md")
    #Dir.chdir(ENV['PWD'])

    existing_entries = File.exists?(changelog) ? File.read(changelog).split("\n").collect { |l| l.strip } : []

    version_delim = "#######"
    version_count = existing_entries.count { |l| l.include?(version_delim) }

    today = "fo/ba/bz" #Date.today.to_s
    username = IO.popen("git config user.name").read.strip || ENV["USER"] || "ac"
    template_args = [today, username]
    opening_line_template = "# [1.#{version_count + 1}.0] - %s - %s\n\n\n\n#{version_delim}\n" % template_args

    new_entry_tmp = Tempfile.new(changelog)
    new_entry_tmp.write(opening_line_template)
    new_entry_tmp.rewind
    new_entry_tmp.close

    if system("vi #{new_entry_tmp.path}")
      new_entry = File.read(new_entry_tmp.path).split("\n").collect { |l| l.strip }

      if new_entry.length > 0
        new_entry << ""

        existing_entries.unshift(*new_entry)
        existing_entries << ""

        #File.write(changelog, existing_entries.join("\n"))
        changelog_fd = File.open(changelog, "w")
        changelog_fd.write(existing_entries.join("\n"))
        changelog_fd.close
      end
    end
  end
  method_added(:changelog)
end
