#

class Wkndr
  ##desc "server [DIRECTORY]", "services given directory over http"
  def self.server(directory = "public")
    if File.exists?(directory)
      log!(:StartServer)
      Server.run!(directory)
    end
  end

  def self.show!(run_loop_blocker = nil)
    running = true
    #TODO: server FPS
    fps = run_loop_blocker.fps
    exit_counter = 0
    tick_interval_ms = ((1.0/fps)*1000.0)
    ticks = 0

    Signal.trap(:INT) { |signo|
      running = false
    }

    if running
      timer = UV::Timer.new
      timer.start(tick_interval_ms, tick_interval_ms) { |x|
        begin
          if running && run_loop_blocker.running
            if ((ticks) % 1000) == 0
              log!(:idle, ticks)
            end

            run_loop_blocker.signal
          else
            if exit_counter > 0
              timer.stop
              run_loop_blocker.shutdown
              #uv_walk to find bug!!, its in client/wslay uv event bits, open timer or something!!!!
              #UV.default_loop.close
              UV.default_loop.stop #TODO: remove once uv leftover handle bug is fixed
            else
              all_halting = run_loop_blocker.halt!
              exit_counter += 1
            end
          end

          ticks += 1
        rescue => e
          log!(:base_running_timer_tick_error, e, e.backtrace)
        end
      }

      UV.run
    end
  end

#NOTE: TODO
#  desc "changelog [CHANGELOG]", "appends changelog item to CHANGELOG.md"
#  def changelog(changelog = "CHANGELOG.md")
#    #Dir.chdir(ENV['PWD'])
#
#    existing_entries = File.exists?(changelog) ? File.read(changelog).split("\n").collect { |l| l.strip } : []
#
#    version_delim = "#######"
#    version_count = existing_entries.count { |l| l.include?(version_delim) }
#
#    today = "fo/ba/bz" #Date.today.to_s
#    username = IO.popen("git config user.name").read.strip || ENV["USER"] || "ac"
#    template_args = [today, username]
#    opening_line_template = "# [1.#{version_count + 1}.0] - %s - %s\n\n\n\n#{version_delim}\n" % template_args
#
#    new_entry_tmp = Tempfile.new(changelog)
#    new_entry_tmp.write(opening_line_template)
#    new_entry_tmp.rewind
#    new_entry_tmp.close
#
#    if system("vi #{new_entry_tmp.path}")
#      new_entry = File.read(new_entry_tmp.path).split("\n").collect { |l| l.strip }
#
#      if new_entry.length > 0
#        new_entry << ""
#
#        existing_entries.unshift(*new_entry)
#        existing_entries << ""
#
#        #File.write(changelog, existing_entries.join("\n"))
#        changelog_fd = File.open(changelog, "w")
#        changelog_fd.write(existing_entries.join("\n"))
#        changelog_fd.close
#      end
#    end
#  end
#  method_added(:changelog)
end