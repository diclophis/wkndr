#

class StackBlocker
  def initialize
    #(for_server)
    #@for_server = for_server
    @stack = []
  end

  def up(o)
    @stack << o
  end

  def fps
    raise "wtf"

    #if @for_server
    #  1
    #else
    #  1
    #end
  end

  def running
    @stack.all? { |srb| 
      srb.running
    }
  end

  def did_connect(&block)
    #Wkndr.log! [:wtf]
    if block
      @did_connect_proc = block
    else
      if @did_connect_proc
        @did_connect_proc.call
      end
    end
  end

  def halt!
    @stack.each { |srb| srb.halt! }
  end

  def shutdown
    @stack.each { |srb| srb.shutdown }
  end

  #TODO: this could be in C maybe???
  def update(cli = 0, gt = 0, dt = 0, sw = 0, sh = 0, touchpoints = nil)
    srb_rr = nil

    #Wkndr.log! [:stack_blocker_update, cli, gt]

    @stack.each { |srb|
      begin
      srb_r = srb.update(cli, gt, dt, sw, sh, touchpoints)
      srb_rr = srb_rr || srb_r
      rescue => e
      end
      #Wkndr.log! [:srb_r, srb_r, cli, self.object_id, :srb_rr, srb_rr]
    }

    srb_rr
  end
end
