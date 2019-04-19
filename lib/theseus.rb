# encoding: UTF-8

module Theseus
  module Formatters
    class ASCII
      # Renders an UpsilonMaze to an ASCII representation, using 3 characters
      # horizontally and 4 characters vertically to represent a single octagonal
      # cell, and 3 characters horizontally and 2 vertically to represent a square
      # cell.
      #    _   _   _  
      #   / \_/ \_/ \ 
      #   | |_| |_| |
      #   \_/ \_/ \_/ 
      #   |_| |_| |_|
      #   / \_/ \_/ \ 
      #
      # You shouldn't ever need to instantiate this class directly. Rather, use
      # UpsilonMaze#to(:ascii) (or UpsilonMaze#to_s to get the string directly).
      class Upsilon < ASCII
        # Returns a new Sigma canvas for the given maze (which should be an
        # instance of SigmaMaze). The +options+ parameter is not used.
        #
        # The returned object will be fully initialized, containing an ASCII
        # representation of the given SigmaMaze.
        def initialize(maze, options={})
          super(maze.width * 2 + 1, maze.height * 2 + 3)

          maze.height.times do |y|
            py = y * 2
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = x * 2

              if (x + y) % 2 == 0
                draw_octogon_cell(px, py, cell)
              else
                draw_square_cell(px, py, cell)
              end
            end
          end
        end

        private

        def draw_octogon_cell(px, py, cell) #:nodoc:
          self[px+1, py]   = "_" if cell & Maze::N == 0
          self[px, py+1]   = "/" if cell & Maze::NW == 0
          self[px+2, py+1] = "\\" if cell & Maze::NE == 0
          self[px, py+2]   = "|" if cell & Maze::W == 0
          self[px+2, py+2] = "|" if cell & Maze::E == 0
          self[px, py+3]   = "\\" if cell & Maze::SW == 0
          self[px+1, py+3] = "_" if cell & Maze::S == 0
          self[px+2, py+3] = "/" if cell & Maze::SE == 0
        end

        def draw_square_cell(px, py, cell) #:nodoc:
          self[px+1, py+1] = "_" if cell & Maze::N == 0
          self[px, py+2]   = "|" if cell & Maze::W == 0
          self[px+1, py+2] = "_" if cell & Maze::S == 0
          self[px+2, py+2] = "|" if cell & Maze::E == 0
        end
      end
    end
  end
end


module Theseus
  module Formatters
    class ASCII
      # Renders an OrthogonalMaze to an ASCII representation.
      #
      # The ASCII formatter for the OrthogonalMaze actually supports three different
      # output types:
      #
      # [:plain]    Uses standard 7-bit ASCII characters. Width is 2x+1, height is
      #             y+1. This mode cannot render weave mazes without significant
      #             ambiguity.
      # [:unicode]  Uses unicode characters to render cleaner lines. Width is
      #             3x, height is 2y. This mode has sufficient detail to correctly
      #             render mazes with weave!
      # [:lines]    Draws passages as lines, using unicode characters. Width is
      #             x, height is y. This mode can render weave mazes, but with some
      #             ambiguity.
      #
      # The :plain mode is the default, but you can specify a different one using
      # the :mode option.
      #
      # You shouldn't ever need to instantiate this class directly. Rather, use
      # OrthogonalMaze#to(:ascii) (or OrthogonalMaze#to_s to get the string directly).
      class Orthogonal < ASCII
        # Returns the dimensions of the given maze, rendered in the given mode.
        # The +mode+ must be +:plain+, +:unicode+, or +:lines+.
        def self.dimensions_for(maze, mode)
          case mode
          when :plain, nil then 
            [maze.width * 2 + 1, maze.height + 1]
          when :unicode then
            [maze.width * 3, maze.height * 2]
          when :lines then
            [maze.width, maze.height]
          else
            abort "unknown mode #{mode.inspect}"
          end
        end

        # Create and return a fully initialized ASCII canvas. The +options+
        # parameter may specify a +:mode+ parameter, as described in the documentation
        # for this class.
        def initialize(maze, options={})
          mode = options[:mode] || :plain

          width, height = self.class.dimensions_for(maze, mode)
          super(width, height)

          maze.height.times do |y|
            length = maze.row_length(y)
            length.times do |x|
              case mode
              when :plain then draw_plain_cell(maze, x, y)
              when :unicode then draw_unicode_cell(maze, x, y)
              when :lines then draw_line_cell(maze, x, y)
              end
            end
          end
        end

        private

        def draw_plain_cell(maze, x, y) #:nodoc:
          c = maze[x, y]
          return if c == 0

          px, py = x * 2, y

          cnw = maze.valid?(x-1,y-1) ? maze[x-1,y-1] : 0
          cn  = maze.valid?(x,y-1) ? maze[x,y-1] : 0
          cne = maze.valid?(x+1,y-1) ? maze[x+1,y-1] : 0
          cse = maze.valid?(x+1,y+1) ? maze[x+1,y+1] : 0
          cs  = maze.valid?(x,y+1) ? maze[x,y+1] : 0
          csw = maze.valid?(x-1,y+1) ? maze[x-1,y+1] : 0

          if c & Maze::N == 0
            self[px, py] = "_" if y == 0 || (cn == 0 && cnw == 0) || cnw & (Maze::E | Maze::S) == Maze::E
            self[px+1, py] = "_"
            self[px+2, py] = "_" if y == 0 || (cn == 0 && cne == 0) || cne & (Maze::W | Maze::S) == Maze::W
          end

          if c & Maze::S == 0
            bottom = y+1 == maze.height
            self[px, py+1] = "_" if bottom || (cs == 0 && csw == 0) || csw & (Maze::E | Maze::N) == Maze::E
            self[px+1, py+1] = "_"
            self[px+2, py+1] = "_" if bottom || (cs == 0 && cse == 0) || cse & (Maze::W | Maze::N) == Maze::W
          end

          self[px, py+1] = "|" if c & Maze::W == 0
          self[px+2, py+1] = "|" if c & Maze::E == 0
        end

        UTF8_SPRITES = [
          ["   ",
           "   "], # " "

          ["│ │", 
           "└─┘"], # "╵" 5

          ["┌─┐", 
           "│ │"], # "╷" 6

          ["│ │", 
           "│ │"], # "│" 10

          ["┌──", 
           "└──"], # "╶" 7

          ["│ └", 
           "└──"], # "└" 

          ["┌──", 
           "│ ┌"], # "┌"

          ["│ └", 
           "│ ┌"], # "├" 3

          ["──┐", 
           "──┘"], # "╴" 8

          ["┘ │", 
           "──┘"], # "┘"

          ["──┐",
           "┐ │"], # "┐"

          ["┘ │",
           "┐ │"], # "┤" 4

          ["───",
           "───"], # "─" 9

          ["┘ └",
           "───"], # "┴" 2

          ["───",
           "┐ ┌"], # "┬" 1

          ["┘ └",
           "┐ ┌"]  # "┼" 0
        ]

        def draw_unicode_cell(maze, x, y) #:nodoc:
          cx, cy = 3 * x, 2 * y
          cell = maze[x, y]

          UTF8_SPRITES[cell & Maze::PRIMARY].each_with_index do |row, sy|
            row.length.times do |sx|
              char = row[sx]
              self[cx+sx, cy+sy] = char
            end
          end

          under = cell >> Maze::UNDER_SHIFT

          if under & Maze::N != 0
            self[cx,   cy] = "┴"
            self[cx+2, cy] = "┴"
          end

          if under & Maze::S != 0
            self[cx,   cy+1] = "┬"
            self[cx+2, cy+1] = "┬"
          end

          if under & Maze::W != 0
            self[cx, cy]   = "┤"
            self[cx, cy+1] = "┤"
          end

          #road coming from right under bridge
          if under & Maze::E != 0
            self[cx+2, cy]   = "├"
            self[cx+2, cy+1] = "├"
          end
        end

        UTF8_LINES = [".", "╵", "╷", "│", "╶", "└", "┌", "├", "╴", "┘", "┐", "┤", "─", "┴", "┬", "┼"]

        def draw_line_cell(maze, x, y) #:nodoc:
          self[x, y] = UTF8_LINES[maze[x, y] & Maze::PRIMARY]
        end
      end
    end
  end
end

module Theseus
  module Formatters
    class ASCII
      # Renders a DeltaMaze to an ASCII representation, using 4 characters
      # horizontally and 2 characters vertically to represent a single cell.
      #
      #          __
      #        /\  /
      #       /__\/
      #      /\  /\ 
      #     /__\/__\ 
      #    /\  /\  /\ 
      #   /__\/__\/__\ 
      #
      # You shouldn't ever need to instantiate this class directly. Rather, use
      # DeltaMaze#to(:ascii) (or DeltaMaze#to_s to get the string directly).
      class Delta < ASCII
        # Returns a new Delta canvas for the given maze (which should be an
        # instance of DeltaMaze). The +options+ parameter is not used.
        #
        # The returned object will be fully initialized, containing an ASCII
        # representation of the given DeltaMaze.
        def initialize(maze, options={})
          super((maze.width + 1) * 2, maze.height * 2 + 1)

          maze.height.times do |y|
            py = y * 2
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = x * 2

              if maze.points_up?(x, y)
                if cell & Maze::W == 0
                  self[px+1,py+1] = "/"
                  self[px,py+2] = "/"
                elsif y < 1
                  self[px+1,py] = "_"
                end

                if cell & Maze::E == 0
                  self[px+2,py+1] = "\\"
                  self[px+3,py+2] = "\\"
                elsif y < 1
                  self[px+2,py] = "_"
                end

                if cell & Maze::S == 0
                  self[px+1,py+2] = self[px+2,py+2] = "_"
                end
              else
                if cell & Maze::W == 0
                  self[px,py+1] = "\\"
                  self[px+1,py+2] = "\\"
                elsif x > 0 && maze[x-1,y] & Maze::S == 0
                  self[px+1,py+2] = "_"
                end

                if cell & Maze::E == 0
                  self[px+3,py+1] = "/"
                  self[px+2,py+2] = "/"
                elsif x < maze.row_length(y) && maze[x+1,y] & Maze::S == 0
                  self[px+2,py+2] = "_"
                end

                if cell & Maze::N == 0
                  self[px+1,py] = self[px+2,py] = "_"
                end
              end
            end
          end
        end
      end
    end
  end
end

module Theseus
  module Formatters
    class ASCII
      # Renders a SigmaMaze to an ASCII representation, using 3 characters
      # horizontally and 3 characters vertically to represent a single cell.
      #    _   _   _
      #   / \_/ \_/ \_
      #   \_/ \_/ \_/ \ 
      #   / \_/ \_/ \_/
      #   \_/ \_/ \_/ \ 
      #   / \_/ \_/ \_/
      #   \_/ \_/ \_/ \ 
      #   / \_/ \_/ \_/
      #   \_/ \_/ \_/ \ 
      #
      # You shouldn't ever need to instantiate this class directly. Rather, use
      # SigmaMaze#to(:ascii) (or SigmaMaze#to_s to get the string directly).
      class Sigma < ASCII
        # Returns a new Sigma canvas for the given maze (which should be an
        # instance of SigmaMaze). The +options+ parameter is not used.
        #
        # The returned object will be fully initialized, containing an ASCII
        # representation of the given SigmaMaze.
        def initialize(maze, options={})
          super(maze.width * 2 + 2, maze.height * 2 + 2)

          maze.height.times do |y|
            py = y * 2
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = x * 2

              shifted = x % 2 != 0
              ry = shifted ? py+1 : py

              nw = shifted ? Maze::W : Maze::NW
              ne = shifted ? Maze::E : Maze::NE
              sw = shifted ? Maze::SW : Maze::W
              se = shifted ? Maze::SE : Maze::E

              self[px+1,ry]   = "_" if cell & Maze::N == 0
              self[px,ry+1]   = "/" if cell & nw == 0
              self[px+2,ry+1] = "\\" if cell & ne == 0
              self[px,ry+2]   = "\\" if cell & sw == 0
              self[px+1,ry+2] = "_" if cell & Maze::S == 0
              self[px+2,ry+2] = "/" if cell & se == 0
            end
          end
        end
      end
    end
  end
end
module Theseus
  # Theseus::Maze is an abstract class, intended to act solely as a superclass
  # for specific maze types. Subclasses include OrthogonalMaze, DeltaMaze,
  # SigmaMaze, and UpsilonMaze.
  #
  # Each cell in the maze is a bitfield. The bits that are set indicate which
  # passages exist leading AWAY from this cell. Bits in the low byte (corresponding
  # to the PRIMARY bitmask) represent passages on the normal plane. Bits
  # in the high byte (corresponding to the UNDER bitmask) represent passages
  # that are passing under this cell. (Under/over passages are controlled via the
  # #weave setting, and are not supported by all maze types.)
  class Maze
    N  = 0x01 # North
    S  = 0x02 # South
    E  = 0x04 # East
    W  = 0x08 # West
    NW = 0x10 # Northwest
    NE = 0x20 # Northeast
    SW = 0x40 # Southwest
    SE = 0x80 # Southeast

    # bitmask identifying directional bits on the primary plane
    PRIMARY  = 0x000000FF

    # bitmask identifying directional bits under the primary plane
    UNDER    = 0x0000FF00

    # bits reserved for use by individual algorithm implementations
    RESERVED = 0xFFFF0000

    # The size of the PRIMARY bitmask (e.g. how far to the left the
    # UNDER bitmask is shifted).
    UNDER_SHIFT = 8

    # The algorithm object used to generate this maze. Defaults to
    # an instance of Algorithms::RecursiveBacktracker.
    attr_reader :algorithm

    # The width of the maze (number of columns).
    #
    # In general, it is safest to use the #row_length method for a particular
    # row, since it is theoretically possible for a maze subclass to describe
    # a different width for each row.
    attr_reader :width

    # The height of the maze (number of rows).
    attr_reader :height

    # An integer between 0 and 100 (inclusive). 0 means passages will only
    # change direction when they encounter a barrier they cannot move through
    # (or under). 100 means that as passages are built, a new direction will
    # always be randomly chosen for each step of the algorithm.
    attr_reader :randomness

    # An integer between 0 and 100 (inclusive). 0 means passages will never
    # move over or under existing passages. 100 means whenever possible,
    # passages will move over or under existing passages. Note that not all
    # maze types support weaving.
    attr_reader :weave

    # An integer between 0 and 100 (inclusive), signifying the percentage
    # of deadends in the maze that will be extended in some direction until
    # they join with an existing passage. This will create loops in the
    # graph. Thus, 0 is a "perfect" maze (with no loops), and 100 is a
    # maze that is totally multiply-connected, with no dead-ends.
    attr_reader :braid

    # One of :none, :x, :y, or :xy, indicating which boundaries the maze
    # should wrap around. The default is :none, indicating no wrapping.
    # If :x, the maze will wrap around the left and right edges. If
    # :y, the maze will wrap around the top and bottom edges. If :xy, the
    # maze will wrap around both edges.
    #
    # A maze that wraps in a single direction may be mapped onto a cylinder.
    # A maze that wraps in both x and y may be mapped onto a torus.
    attr_reader :wrap

    # A Theseus::Mask (or similar) instance, that is used by the algorithm to
    # determine which cells in the space are allowed. This lets you create
    # mazes that fill shapes, or flow around patterns.
    attr_reader :mask

    # One of :none, :x, :y, :xy, or :radial. Note that not all maze types
    # support symmetry. The :x symmetry means the maze will be mirrored
    # across the x axis. Similarly, :y symmetry means the maze will be
    # mirrored across the y axis. :xy symmetry causes the maze to be
    # mirrored across both axes, and :radial symmetry causes the maze to
    # be mirrored radially about the center of the maze.
    attr_reader :symmetry

    # A 2-tuple (array) indicating the x and y coordinates where the maze
    # should be entered. This is used primarly when generating the solution
    # to the maze, and generally defaults to the upper-left corner.
    attr_reader :entrance

    # A 2-tuple (array) indicating the x and y coordinates where the maze
    # should be exited. This is used primarly when generating the solution
    # to the maze, and generally defaults to the lower-right corner.
    attr_reader :exit

    # A short-hand method for creating a new maze object and causing it to
    # be generated, in one step. Returns the newly generated maze.
    def self.generate(options={})
      new(options).generate!
    end

    # Creates and returns a new maze object. Note that the maze will _not_
    # be generated; the maze is initially blank.
    #
    # Many options are supported:
    #
    # [:width]       The number of columns in the maze. Note that different
    #                maze types count columns and rows differently; you'll
    #                want to see individual maze types for more info.
    # [:height]      The number of rows in the maze.
    # [:algorithm]   The maze algorithm to use. This should be a class,
    #                adhering to the interface described by Theseus::Algorithms::Base.
    #                It defaults to Theseus::Algorithms::RecursiveBacktracker.
    # [:symmetry]    The symmetry to be used when generating the maze. This
    #                defaults to +:none+, but may also be +:x+ (to have the
    #                maze mirrored across the x-axis), +:y+ (to mirror the
    #                maze across the y-axis), +:xy+ (to mirror across both
    #                axes simultaneously), and +:radial+ (to mirror the maze
    #                radially about the center). Some symmetry types may
    #                result in loops being added to the maze, regardless of
    #                the braid value (see the +:braid+ parameter).
    #                (NOTE: not all maze types support symmetry equally.)
    # [:randomness]  An integer between 0 and 100 (inclusive) indicating how
    #                randomly the maze is generated. A 0 means that the maze
    #                passages will prefer to go straight whenever possible.
    #                A 100 means the passages will choose random directions
    #                as often as possible.
    # [:mask]        An instance of Theseus::Mask (or something that acts
    #                similarly). This can be used to constrain the maze so that
    #                it fills or avoids specific areas, so that shapes and
    #                patterns can be made. (NOTE: not all algorithms support
    #                masks.)
    # [:weave]       An integer between 0 and 100 (inclusive) indicating how
    #                frequently passages move under or over other passages.
    #                A 0 means the passages will never move over/under other
    #                passages, while a 100 means they will do so as often
    #                as possible. (NOTE: not all maze types and algorithms
    #                support weaving.)
    # [:braid]       An integer between 0 and 100 (inclusive) representing
    #                the percentage of dead-ends that should be removed after
    #                the maze has been generated. Dead-ends are removed by
    #                extending them in some direction until they join with
    #                another passage. This will introduce loops into the maze,
    #                making it "multiply-connected". A braid value of 0 will
    #                always result in a "perfect" maze (with no loops), while
    #                a value of 100 will result in a maze with no dead-ends.
    # [:wrap]        Indicates which edges of the maze should wrap around.
    #                +:x+ will cause the left and right edges to wrap, and
    #                +:y+ will cause the top and bottom edges to wrap. You
    #                can specify +:xy+ to wrap both left-to-right and
    #                top-to-bottom. The default is +:none+ (for no wrapping).
    # [:entrance]    A 2-tuple indicating from where the maze is entered.
    #                By default, the maze's entrance will be the upper-left-most
    #                point. Note that it may lie outside the bounds of the maze
    #                by one cell (e.g. [-1,0]), indicating that the entrance
    #                is on the very edge of the maze.
    # [:exit]        A 2-tuple indicating from where the maze is exited.
    #                By default, the maze's entrance will be the lower-right-most
    #                point. Note that it may lie outside the bounds of the maze
    #                by one cell (e.g. [width,height-1]), indicating that the
    #                exit is on the very edge of the maze.
    # [:prebuilt]    Sometimes, you may want the new maze to be considered to be
    #                generated, but not actually have anything generated into it.
    #                You can set the +:prebuilt+ parameter to +true+ in this case,
    #                allowing you to then set the contents of the maze by hand,
    #                using the #[]= method.
    def initialize(options={})
      @deadends = nil

      @width = (options[:width] || 10).to_i
      @height = (options[:height] || 10).to_i

      @symmetry = (options[:symmetry] || :none).to_sym
      configure_symmetry

      @randomness = options[:randomness] || 100
      @mask = options[:mask] || TransparentMask.new
      @weave = options[:weave] || 0
      @braid = options[:braid] || 0
      @wrap = options[:wrap] || :none

      @cells = setup_grid or raise "expected #setup_grid to return the new grid"

      @entrance = options[:entrance] || default_entrance
      @exit = options[:exit] || default_exit

      algorithm_class = options[:algorithm] || Algorithms::RecursiveBacktracker
      @algorithm = algorithm_class.new(self, options)

      @generated = options[:prebuilt]
    end

    # Generates the maze if it has not already been generated. This is
    # essentially the same as calling #step repeatedly. If a block is given,
    # it will be called after each step.
    def generate!
      yield if block_given? while step unless generated?
      self
    end

    # Creates a new Theseus::Path object based on this maze instance. This can
    # be used to (for instance) create special areas of the maze or routes through
    # the maze that you want to color specially. The following demonstrates setting
    # a particular cell in the maze to a light-purple color:
    #
    #   path = maze.new_path(color: 0xff7fffff)
    #   path.set([5,5])
    #   maze.to(:png, paths: [path])
    def new_path(meta={})
      Path.new(self, meta)
    end

    # Instantiates and returns a new solver instance which encapsulates a
    # solution algorithm. The options may contain the following keys:
    #
    # [:type] This defaults to +:backtracker+ (for the Theseus::Solvers::Backtracker
    #         solver), but may also be set to +:astar+ (for the Theseus::Solvers::Astar
    #         solver).
    # [:a]    A 2-tuple (defaulting to #start) that says where in the maze the
    #         solution should begin.
    # [:b]    A 2-tuple (defaulting to #finish) that says where in the maze the
    #         solution should finish.
    #
    # The returned solver will not yet have generated the solution. Use
    # Theseus::Solvers::Base#solve or Theseus::Solvers::Base#step to generate the
    # solution.
    def new_solver(options={})
      type = options[:type] || :backtracker

      require "theseus/solvers/#{type}"
      klass = Theseus::Solvers.const_get(type.to_s.capitalize)

      a = options[:a] || start
      b = options[:b] || finish

      klass.new(self, a, b)
    end

    # Returns the solution for the maze as an array of 2-tuples, each indicating
    # a cell (in sequence) leading from the start to the finish.
    #
    # See #new_solver for a description of the supported options.
    def solve(options={})
      new_solver(options).solution
    end

    # Returns the bitfield for the cell at the given (+x+,+y+) coordinate.
    def [](x,y)
      @cells[y][x]
    end

    # Sets the bitfield for the cell at the given (+x+,+y+) coordinate.
    def []=(x,y,value)
      @cells[y][x] = value
    end

    # Completes a single iteration of the maze generation algorithm. Returns
    # +false+ if the method should not be called again (e.g., the maze has
    # been completed), and +true+ otherwise.
    def step
      return false if @generated

      if @deadends && @deadends.any?
        dead_end = @deadends.pop
        braid_cell(dead_end[0], dead_end[1])

        @generated = @deadends.empty?
        return !@generated
      end

      if @algorithm.step
        return true
      else
        return finish!
      end
    end

    # Returns +true+ if the maze has been generated.
    def generated?
      @generated
    end

    # Since #entrance may be external to the maze, #start returns the cell adjacent to
    # #entrance that lies within the maze. If #entrance is already internal to the
    # maze, this method returns #entrance. If #entrance is _not_ adjacent to any
    # internal cell, this method returns +nil+.
    def start
      adjacent_point(@entrance)
    end

    # Since #exit may be external to the maze, #finish returns the cell adjacent to
    # #exit that lies within the maze. If #exit is already internal to the
    # maze, this method returns #exit. If #exit is _not_ adjacent to any
    # internal cell, this method returns +nil+.
    def finish
      adjacent_point(@exit)
    end

    # Returns an array of the possible exits for the cell at the given coordinates.
    # Note that this does not take into account boundary conditions: a move in any
    # of the returned directions may not actually be valid, and should be verified
    # before being applied.
    #
    # This is used primarily by subclasses to allow for different shaped cells
    # (e.g. hexagonal cells for SigmaMaze, octagonal cells for UpsilonMaze).
    def potential_exits_at(x, y)
      raise NotImplementedError, "subclasses must implement #potential_exits_at"
    end

    # Returns true if the maze may be wrapped in the x direction (left-to-right).
    def wrap_x?
      @wrap == :x || @wrap == :xy
    end

    # Returns true if the maze may be wrapped in the y direction (top-to-bottom).
    def wrap_y?
      @wrap == :y || @wrap == :xy
    end

    # Returns true if the given coordinates are valid within the maze. This will
    # be the case if:
    #
    # 1. The coordinates lie within the maze's bounds, and
    # 2. The current mask for the maze does not restrict the location.
    #
    # If the maze wraps in x, the x coordinate is unconstrained and will be
    # mapped (via modulo) to the bounds. Similarly, if the maze wraps in y,
    # the y coordinate will be unconstrained.
    def valid?(x, y)
      return false if !wrap_y? && (y < 0 || y >= height)
      y %= height
      return false if !wrap_x? && (x < 0 || x >= row_length(y))
      x %= row_length(y)
      return @mask[x, y]
    end

    # Moves the given (+x+,+y+) coordinates a single step in the given
    # +direction+. If wrapping in either x or y is active, the result will
    # be mapped to the maze's current bounds via modulo arithmetic. The
    # resulting coordinates are returned as a 2-tuple.
    #
    # Example:
    #
    #   x2, y2 = maze.move(x, y, Maze::W)
    def move(x, y, direction)
      nx, ny = x + dx(direction), y + dy(direction)

      ny %= height if wrap_y?
      nx %= row_length(ny) if wrap_x? && ny > 0 && ny < height

      [nx, ny]
    end

    # Returns a array of all dead-ends in the maze. Each element of the array
    # is a 2-tuple containing the coordinates of a dead-end.
    def dead_ends
      dead_ends = []

      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          dead_ends << [x, y] if dead?(cell)
        end
      end

      dead_ends
    end

    # Removes one cell from all dead-ends in the maze. Each call to this method
    # removes another level of dead-ends, making the maze increasingly sparse.
    def sparsify!
      dead_ends.each do |(x, y)|
        cell = @cells[y][x]
        direction = cell & PRIMARY
        nx, ny = move(x, y, direction)

        # if the cell includes UNDER codes, shifting it all UNDER_SHIFT bits to the right
        # will convert those UNDER codes to PRIMARY codes. Otherwise, it will
        # simply zero the cell, resulting in a blank spot.
        @cells[y][x] >>= UNDER_SHIFT

        # if it's a weave cell (that moves over or under another corridor),
        # nix it and move back one more, so we don't wind up with dead-ends
        # underneath another corridor.
        if @cells[ny][nx] & (opposite(direction) << UNDER_SHIFT) != 0
          @cells[ny][nx] &= ~((direction | opposite(direction)) << UNDER_SHIFT)
          nx, ny = move(nx, ny, direction)
        end

        @cells[ny][nx] &= ~opposite(direction)
      end
    end

    # Returns the direction opposite to the given +direction+. This will work
    # even if the +direction+ value is in the UNDER bitmask.
    def opposite(direction)
      if direction & UNDER != 0
        opposite(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then S
        when S  then N
        when E  then W
        when W  then E
        when NE then SW
        when NW then SE
        when SE then NW
        when SW then NE
        end
      end
    end

    # Returns the direction that is the horizontal mirror to the given +direction+.
    # This will work even if the +direction+ value is in the UNDER bitmask.
    def hmirror(direction)
      if direction & UNDER != 0
        hmirror(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when E  then W
        when W  then E
        when NW then NE
        when NE then NW
        when SW then SE
        when SE then SW
        else direction
        end
      end
    end

    # Returns the direction that is the vertical mirror to the given +direction+.
    # This will work even if the +direction+ value is in the UNDER bitmask.
    def vmirror(direction)
      if direction & UNDER != 0
        vmirror(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then S
        when S  then N
        when NE then SE
        when NW then SW
        when SE then NE
        when SW then NW
        else direction
        end
      end
    end

    # Returns the direction that results by rotating the given +direction+
    # 90 degrees in the clockwise direction. This will work even if the +direction+
    # value is in the UNDER bitmask.
    def clockwise(direction)
      if direction & UNDER != 0
        clockwise(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then E
        when E  then S
        when S  then W
        when W  then N
        when NW then NE
        when NE then SE
        when SE then SW
        when SW then NW
        end
      end
    end

    # Returns the direction that results by rotating the given +direction+
    # 90 degrees in the counter-clockwise direction. This will work even if
    # the +direction+ value is in the UNDER bitmask.
    def counter_clockwise(direction)
      if direction & UNDER != 0
        counter_clockwise(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then W
        when W  then S
        when S  then E
        when E  then N
        when NW then SW
        when SW then SE
        when SE then NE
        when NE then NW
        end
      end
    end

    # Returns the change in x implied by the given +direction+.
    def dx(direction)
      case direction
      when E, NE, SE then 1
      when W, NW, SW then -1
      else 0
      end
    end

    # Returns the change in y implied by the given +direction+.
    def dy(direction)
      case direction
      when S, SE, SW then 1
      when N, NE, NW then -1
      else 0
      end
    end

    # Returns the number of cells in the given row. This is generally safer
    # than relying the #width method, since it is theoretically possible for
    # a maze to have a different number of cells for each of its rows.
    def row_length(row)
      @cells[row].length
    end

    # Returns +true+ if the given cell is a dead-end. This considers only
    # passages on the PRIMARY plane (the UNDER bits are ignored, because the
    # current algorithm for generating mazes will never result in a dead-end
    # that is underneath another passage).
    def dead?(cell)
      raw = cell & PRIMARY
      raw == N || raw == S || raw == E || raw == W ||
        raw == NE || raw == NW || raw == SE || raw == SW
    end

    # If +point+ is already located at a valid point within the maze, this
    # does nothing. Otherwise, it examines the potential exits from the
    # given point and looks for the first one that leads immediately to a
    # valid point internal to the maze. When it finds one, it adds a passage
    # to that cell leading to +point+. If no such adjacent cell exists, this
    # method silently does nothing.
    def add_opening_from(point)
      x, y = point
      if valid?(x, y)
        # nothing to be done
      else
        potential_exits_at(x, y).each do |direction|
          nx, ny = move(x, y, direction)
          if valid?(nx, ny)
            @cells[ny][nx] |= opposite(direction)
            return
          end
        end
      end
    end

    # If +point+ is already located at a valid point withint he maze, this
    # simply returns +point+. Otherwise, it examines the potential exits
    # from the given point and looks for the first one that leads immediately
    # to a valid point internal to the maze. When it finds one, it returns
    # that point. If no such point exists, it returns +nil+.
    def adjacent_point(point)
      x, y = point
      if valid?(x, y)
        point
      else
        potential_exits_at(x, y).each do |direction|
          nx, ny = move(x, y, direction)
          return [nx, ny] if valid?(nx, ny)
        end
      end
    end

    # Returns the direction of +to+ relative to +from+. +to+ and +from+
    # are both points (2-tuples).
    def relative_direction(from, to)
      # first, look for the case where the maze wraps, and from and to
      # are on opposite sites of the grid.
      if wrap_x? && from[1] == to[1] && (from[0] == 0 || to[0] == 0) && (from[0] == @width-1 || to[0] == @width-1)
        if from[0] < to[0]
          W
        else
          E
        end
      elsif wrap_y? && from[0] == to[0] && (from[1] == 0 || to[1] == 0) && (from[1] == @height-1 || to[1] == @height-1)
        if from[1] < to[1]
          N
        else
          S
        end
      elsif from[0] < to[0]
        if from[1] < to[1]
          SE
        elsif from[1] > to[1]
          NE
        else
          E
        end
      elsif from[0] > to[0]
        if from[1] < to[1]
          SW
        elsif from[1] > to[1]
          NW
        else
          W
        end
      elsif from[1] < to[1]
        S
      elsif from[1] > to[1]
        N
      else
        # same point!
        nil
      end
    end

    # Applies a move in the given direction to the cell at (x,y). The +direction+
    # parameter may also be :under, in which case the cell is left-shifted so as
    # to move the existing passages to the UNDER plane.
    #
    # This method also handles the application of symmetrical moves, in the case
    # where #symmetry has been specified.
    #
    # You'll generally never call this method directly, except to construct grids
    # yourself.
    def apply_move_at(x, y, direction)
      if direction == :under
        @cells[y][x] <<= UNDER_SHIFT
      else
        @cells[y][x] |= direction
      end

      case @symmetry
      when :x      then move_symmetrically_in_x(x, y, direction)
      when :y      then move_symmetrically_in_y(x, y, direction)
      when :xy     then move_symmetrically_in_xy(x, y, direction)
      when :radial then move_symmetrically_radially(x, y, direction)
      end
    end

    # Returns the type of the maze as a string. OrthogonalMaze, for
    # instance, is reported as "orthogonal".
    def type
      self.class.to_s.split("::")[1].gsub("Maze", "") #[/::(.*?)Maze$/, 1]
    end

    # Returns the maze rendered to a particular format. Supported
    # formats are currently :ascii and :png. The +options+ hash is passed
    # through to the formatter.
    def to(format, options={})
      case format
      when :ascii then
        #require "theseus/formatters/ascii/#{type.downcase}"
        #puts type
        #TODO
        Formatters::ASCII.const_get(type).new(self, options)
        #Formatters::ASCII::Orthogonal.new(self, options)
      when :png then
        require "theseus/formatters/png/#{type.downcase}"
        Formatters::PNG.const_get(type).new(self, options).to_blob
      else
        raise ArgumentError, "unknown format: #{format.inspect}"
      end
    end

    # Returns the maze rendered to a string.
    def to_s(options={})
      to(:ascii, options).to_s
    end

    def inspect # :nodoc:
      "#<#{self.class}:0x%X %dx%d %s>" % [
        object_id, @width, @height,
        generated? ? "generated" : "not generated"]
    end

    # Returns +true+ if a weave may be applied at (thru_x,thru_y) when moving
    # from (from_x,from_y) in +direction+. This will be true if the thru cell
    # does not already have anything in its UNDER plane, and if the cell
    # on the far side of thru is valid and blank.
    #
    # Subclasses may need to override this method if special interpretations
    # for +direction+ need to be considered (see SigmaMaze).
    def weave_allowed?(from_x, from_y, thru_x, thru_y, direction) #:nodoc:
      nx2, ny2 = move(thru_x, thru_y, direction)
      return (@cells[thru_y][thru_x] & UNDER == 0) && valid?(nx2, ny2) && @cells[ny2][nx2] == 0
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction) #:nodoc:
      if rand(2) == 0 # move under existing passage
        apply_move_at(to_x, to_y, direction << UNDER_SHIFT)
        apply_move_at(to_x, to_y, opposite(direction) << UNDER_SHIFT)
      else # move over existing passage
        apply_move_at(to_x, to_y, :under)
        apply_move_at(to_x, to_y, direction)
        apply_move_at(to_x, to_y, opposite(direction))
      end

      nx, ny = move(to_x, to_y, direction)
      [nx, ny, direction]
    end

    private

    # Not all maze types support symmetry. If a subclass supports any of the
    # symmetry types (or wants to implement its own), it should override this
    # method.
    def configure_symmetry #:nodoc:
      if @symmetry != :none
        raise NotImplementedError, "only :none symmetry is implemented by default"
      end
    end

    # The default grid should suffice for most maze types, but if a subclass
    # wants a custom grid, it must override this method. Note that the method
    # MUST always return an Array of rows, with each row being an Array of cells.
    def setup_grid #:nodoc:
      Array.new(height) { Array.new(width, 0) }
    end

    # Returns an array of deadends that ought to be braided (removed), based on
    # the value of the #braid setting.
    def deadends_to_braid #:nodoc:
      return [] if @braid == 0

      ends = dead_ends

      count = ends.length * @braid / 100
      count = 1 if count < 1

      ends.shuffle[0,count]
    end

    # Calculate the default entrance, by looking for the upper-leftmost point.
    def default_entrance #:nodoc:
      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          return [x-1, y] if @mask[x, y]
        end
      end
      [0, 0] # if every cell is masked, then 0,0 is as good as any!
    end

    # Calculate the default exit, by looking for the lower-rightmost point.
    def default_exit #:nodoc:
      @cells.reverse.each_with_index do |row, y|
        ry = @cells.length - y - 1
        row.reverse.each_with_index do |cell, x|
          rx = row.length - x - 1
          return [rx+1, ry] if @mask[rx, ry]
        end
      end
      [0, 0] # if every cell is masked, then 0,0 is as good as any!
    end

    def move_symmetrically_in_x(x, y, direction) #:nodoc:
      row_width = @cells[y].length
      if direction == :under
        @cells[y][row_width - x - 1] <<= UNDER_SHIFT
      else
        @cells[y][row_width - x - 1] |= hmirror(direction)
      end
    end

    def move_symmetrically_in_y(x, y, direction) #:nodoc:
      if direction == :under
        @cells[@cells.length - y - 1][x] <<= UNDER_SHIFT
      else
        @cells[@cells.length - y - 1][x] |= vmirror(direction)
      end
    end

    def move_symmetrically_in_xy(x, y, direction) #:nodoc:
      row_width = @cells[y].length
      if direction == :under
        @cells[y][row_width - x - 1] <<= UNDER_SHIFT
        @cells[@cells.length - y - 1][x] <<= UNDER_SHIFT
        @cells[@cells.length - y - 1][row_width - x - 1] <<= UNDER_SHIFT
      else
        @cells[y][row_width - x - 1] |= hmirror(direction)
        @cells[@cells.length - y - 1][x] |= vmirror(direction)
        @cells[@cells.length - y - 1][row_width - x - 1] |= opposite(direction)
      end
    end

    def move_symmetrically_radially(x, y, direction) #:nodoc:
      row_width = @cells[y].length
      if direction == :under
        @cells[@cells.length - x - 1][y] <<= UNDER_SHIFT
        @cells[x][row_width - y - 1] <<= UNDER_SHIFT
        @cells[@cells.length - y - 1][row_width - x - 1] <<= UNDER_SHIFT
      else
        @cells[@cells.length - x - 1][y] |= counter_clockwise(direction)
        @cells[x][row_width - y - 1] |= clockwise(direction)
        @cells[@cells.length - y - 1][row_width - x - 1] |= opposite(direction)
      end
    end

    # Finishes the generation of the maze by adding openings for the entrance
    # and exit, and determing which dead-ends to braid (if any).
    def finish! #:nodoc:
      add_opening_from(@entrance)
      add_opening_from(@exit)

      @deadends = deadends_to_braid
      @generated = @deadends.empty?

      return !@generated
    end

    # If (x,y) is not a dead-end, this does nothing. Otherwise, it extends the
    # dead-end in some direction until it joins with another passage.
    #
    # TODO: look for the direction that results in the longest loop.
    # might be kind of spendy, but worth trying, at least.
    def braid_cell(x, y) #:nodoc:
      return unless dead?(@cells[y][x])
      tries = potential_exits_at(x, y)
      [opposite(@cells[y][x]), *tries].each do |try|
        next if try == @cells[y][x]
        nx, ny = move(x, y, try)
        if valid?(nx, ny)
          opp = opposite(try)
          next if @cells[ny][nx] & (opp << UNDER_SHIFT) != 0
          @cells[y][x] |= try
          @cells[ny][nx] |= opp
          return
        end
      end
    end

  end
end
module Theseus
  # A "sigma" maze is one in which the field is tesselated into hexagons.
  # Trying to map such a field onto a two-dimensional grid is a little tricky;
  # Theseus does so by treating a single row as the hexagon in the first
  # column, then the hexagon below and to the right, then the next hexagon
  # above and to the right (on a line with the first hexagon), and so forth.
  # For example, the following grid consists of two rows of 8 cells each:
  #
  #    _   _   _   _
  #   / \_/ \_/ \_/ \_
  #   \_/ \_/ \_/ \_/ \ 
  #   / \_/ \_/ \_/ \_/ 
  #   \_/ \_/ \_/ \_/ \ 
  #     \_/ \_/ \_/ \_/ 
  #
  # SigmaMaze supports weaving, but not symmetry (yet).
  #
  #   maze = Theseus::SigmaMaze.generate(width: 10)
  #   puts maze
  class SigmaMaze < Maze

    # Because of how the cells are positioned relative to other cells in
    # the same row, the definition of the diagonal walls changes depending
    # on whether a cell is "shifted" (e.g. moved down a half-row) or not.
    #
    #    ____        ____
    #   / N  \      /
    #  /NW  NE\____/
    #  \W    E/ N  \
    #   \_S__/W    E\____
    #        \SW  SE/
    #         \_S__/
    #
    # Thus, if a cell is shifted, W/E are in the upper diagonals, otherwise
    # they are in the lower diagonals. It is important that W/E always point
    # to cells in the same row, so that the #dx and #dy methods do not need
    # to be overridden.
    #
    # This change actually makes it fairly easy to generalize the other
    # operations, although weaving needs special attention (see #weave_allowed?
    # and #perform_weave).
    def potential_exits_at(x, y) #:nodoc:
      [N, S, E, W] + 
        ((x % 2 == 0) ? [NW, NE] : [SW, SE])
    end

    private

    # This maps which axis the directions share, depending on whether a cell
    # is shifted (+true+) or not (+false+). For example, in a non-shifted cell,
    # E is on a line with NW, so AXIS_MAP[false][E] returns NW (and vice versa).
    # This is used in the weaving algorithms to determine which direction an
    # UNDER passage moves as it passes under a cell.
    AXIS_MAP = {
      false => {
        N => S,
        S => N,
        E => NW,
        NW => E,
        W => NE,
        NE => W
      },

      true => {
        N => S,
        S => N,
        W => SE,
        SE => W,
        E => SW,
        SW => E
      }
    }

    # given a path entering in +entrance_direction+, returns the side of the
    # cell that it would exit if it passed in a straight line through the cell.
    def exit_wound(entrance_direction, shifted) #:nodoc:
      # if moving W into the cell, then entrance_direction == W. To determine
      # the axis within the new cell, we reverse it to find the wall within the
      # cell that was penetrated (opposite(W) == E), and then
      # look it up in the AXIS_MAP (E<->NW or E<->SW, depending on the cell position)
      entrance_wall = opposite(entrance_direction)
      AXIS_MAP[shifted][entrance_wall]
    end

    def weave_allowed?(from_x, from_y, thru_x, thru_y, direction) #:nodoc:
      # disallow a weave if there is already a weave at this cell
      return false if @cells[thru_y][thru_x] & UNDER != 0

      pass_thru = exit_wound(direction, thru_x % 2 != 0)
      out_x, out_y = move(thru_x, thru_y, pass_thru)
      return valid?(out_x, out_y) && @cells[out_y][out_x] == 0
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction) #:nodoc:
      shifted = to_x % 2 != 0
      pass_thru = exit_wound(direction, shifted)

      apply_move_at(to_x, to_y, pass_thru << UNDER_SHIFT)
      apply_move_at(to_x, to_y, AXIS_MAP[shifted][pass_thru] << UNDER_SHIFT)

      nx, ny = move(to_x, to_y, pass_thru)
      [nx, ny, pass_thru]
    end
  end
end
module Theseus
  # The current version of the Theseus library.
  module Version
    MAJOR = 1
    MINOR = 1
    TINY  = 0

    STRING = [MAJOR, MINOR, TINY].join(".")
  end
end
module Theseus
  # A "delta" maze is one in which the field is tesselated into triangles. Thus,
  # each cell has three potential exits: east, west, and either north or south
  # (depending on the orientation of the cell).
  #
  #      __  __  __
  #    /\  /\  /\  /
  #   /__\/__\/__\/
  #   \  /\  /\  /\ 
  #    \/__\/__\/__\ 
  #    /\  /\  /\  /
  #   /__\/__\/__\/
  #   \  /\  /\  /\ 
  #    \/__\/__\/__\ 
  #   
  #
  # Delta mazes in Theseus do not support either weaving, or symmetry.
  #
  #   maze = Theseus::DeltaMaze.generate(width: 10)
  #   puts maze
  class DeltaMaze < Maze
    def initialize(options={}) #:nodoc:
      super
      raise ArgumentError, "weaving is not supported for delta mazes" if @weave > 0
    end

    # Returns +true+ if the cell at (x,y) is oriented so the vertex is "up", or
    # north. Cells for which this returns +true+ may have exits on the south border,
    # and cells for which it returns +false+ may have exits on the north.
    def points_up?(x, y)
      (x + y) % 2 == height % 2
    end

    def potential_exits_at(x, y) #:nodoc:
      vertical = points_up?(x, y) ? S : N

      # list the vertical direction twice. Otherwise the horizontal direction (E/W)
      # will be selected more often (66% of the time), resulting in mazes with a
      # horizontal bias.
      [vertical, vertical, E, W]
    end
  end
end


module Theseus
  # An orthogonal maze is one in which the field is tesselated into squares. This is
  # probably the type of maze that most people think of, when they think of mazes.
  #
  # The orthogonal maze implementation in Theseus is the most complete, supporting
  # weaving as well as all four symmetry types. You can even convert any "perfect"
  # (no loops) orthogonal maze to a "unicursal" maze. (Unicursal means "one course",
  # and refers to a maze that has no junctions, only a single path that takes you
  # through every cell in the maze exactly once.)
  #
  #   maze = Theseus::OrthogonalMaze.generate(width: 10)
  #   puts maze
  class OrthogonalMaze < Maze
    def potential_exits_at(x, y) #:nodoc:
      [N, S, E, W]
    end

    # Extends Maze#finish! to make sure symmetrical mazes are properly closed.
    #--
    # Eventually, this would be good to generalize somehow, and make available to
    # the other maze types.
    #++
    def finish! #:nodoc:
      # for symmetrical mazes, if the size of the maze in the direction of reflection is
      # even, then we have two distinct halves that need to be joined in order for the
      # maze to be fully connected.

      available_width, available_height = @width, @height

      case @symmetry
      when :x then
        available_width = available_width / 2
      when :y then
        available_height = available_height / 2
      when :xy, :radial then 
        available_width = available_width / 2
        available_height = available_height / 2
      end

      connector = lambda do |x, y, ix, iy, dir|
        start_x, start_y = x, y
        while @cells[y][x] == 0
          y = (y + iy) % available_height
          x = (x + ix) % available_width
          break if start_x == x || start_y == y
        end

        if @cells[y][x] == 0
          warn "maze cannot be fully connected"
          nil
        else
          @cells[y][x] |= dir
          nx, ny = move(x, y, dir)
          @cells[ny][nx] |= opposite(dir)
          [x,y]
        end
      end

      even = lambda { |x| x % 2 == 0 }

      case @symmetry
        when :x then
          connector[available_width-1, rand(available_height), 0, 1, E] if even[@width]
        when :y then
          connector[rand(available_width), available_height-1, 1, 0, S] if even[@height]
        when :xy then
          if even[@width]
            x, y = connector[available_width-1, rand(available_height), 0, 1, E]
            @cells[@height-y-1][x] |= E
            @cells[@height-y-1][x+1] |= W
          end

          if even[@height]
            x, y = connector[rand(available_width), available_height-1, 1, 0, S]
            @cells[y][@width-x-1] |= S
            @cells[y+1][@width-x-1] |= N
          end
        when :radial then
          if even[@width]
            @cells[available_height-1][available_width-1] |= E | S
            @cells[available_height-1][available_width] |= W | S
            @cells[available_height][available_width-1] |= E | N
            @cells[available_height][available_width] |= W | N
          end
      end

      super
    end

    # Takes the current orthogonal maze and converts it into a unicursal maze. A unicursal
    # maze is one with only a single path, and no dead-ends or junctions. Such mazes are
    # more properly called "labyrinths". Note that although this method will always return
    # a new OrthogonalMaze instance, it is not guaranteed to be a valid maze unless the
    # current maze is "perfect" (not braided, containing no loops).
    #
    # The resulting unicursal maze will be twice as wide and twice as high as the original
    # maze.
    #
    # The +options+ hash can be used to specify the <code>:entrance</code> and
    # <code>:exit</code> points for the resulting maze. Currently, both the entrance and
    # the exit must be adjacent.
    #
    # The process of converting an orthogonal maze to a unicursal maze is straightforward;
    # take the maze, and divide all passages in half down the middle, making two passages.
    # Dead-ends become a u-turn, etc. This is why the maze increases in size.
    def to_unicursal(options={})
      unicursal = OrthogonalMaze.new(options.merge(width: @width*2, height: @height*2, prebuilt: true))

      set = lambda do |x, y, direction, *recip|
        nx, ny = move(x, y, direction)
        unicursal[x,y] |= direction
        unicursal[nx, ny] |= opposite(direction) if recip[0]
      end

      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          x2 = x * 2
          y2 = y * 2

          if cell & N != 0
            set[x2, y2, N]
            set[x2+1, y2, N]
            set[x2, y2+1, N, true] if cell & W == 0
            set[x2+1, y2+1, N, true] if cell & E == 0
            set[x2, y2+1, E, true] if (cell & PRIMARY) == N
          end

          if cell & S != 0
            set[x2, y2+1, S]
            set[x2+1, y2+1, S]
            set[x2, y2, S, true] if cell & W == 0
            set[x2+1, y2, S, true] if cell & E == 0
            set[x2, y2, E, true] if (cell & PRIMARY) == S
          end

          if cell & W != 0
            set[x2, y2, W]
            set[x2, y2+1, W]
            set[x2+1, y2, W, true] if cell & N == 0
            set[x2+1, y2+1, W, true] if cell & S == 0
            set[x2+1, y2, S, true] if (cell & PRIMARY) == W
          end

          if cell & E != 0
            set[x2+1, y2, E]
            set[x2+1, y2+1, E]
            set[x2, y2, E, true] if cell & N == 0
            set[x2, y2+1, E, true] if cell & S == 0
            set[x2, y2, S, true] if (cell & PRIMARY) == E
          end

          if cell & (N << UNDER_SHIFT) != 0
            unicursal[x2, y2] |= (N | S) << UNDER_SHIFT
            unicursal[x2+1, y2] |= (N | S) << UNDER_SHIFT
            unicursal[x2, y2+1] |= (N | S) << UNDER_SHIFT
            unicursal[x2+1, y2+1] |= (N | S) << UNDER_SHIFT
          elsif cell & (W << UNDER_SHIFT) != 0
            unicursal[x2, y2] |= (E | W) << UNDER_SHIFT
            unicursal[x2+1, y2] |= (E | W) << UNDER_SHIFT
            unicursal[x2, y2+1] |= (E | W) << UNDER_SHIFT
            unicursal[x2+1, y2+1] |= (E | W) << UNDER_SHIFT
          end
        end
      end

      enter_at = unicursal.adjacent_point(unicursal.entrance)
      exit_at = unicursal.adjacent_point(unicursal.exit)

      if enter_at && exit_at
        unicursal.add_opening_from(unicursal.entrance)
        unicursal.add_opening_from(unicursal.exit)

        if enter_at[0] < exit_at[0]
          unicursal[enter_at[0], enter_at[1]] &= ~E
          unicursal[enter_at[0]+1, enter_at[1]] &= ~W
        elsif enter_at[1] < exit_at[1]
          unicursal[enter_at[0], enter_at[1]] &= ~S
          unicursal[enter_at[0], enter_at[1]+1] &= ~N
        end
      end

      return unicursal
    end

    private

    def configure_symmetry #:nodoc:
      if @symmetry == :radial && @width != @height
        raise ArgumentError, "radial symmetrial is only possible for mazes where width == height"
      end
    end
  end
end
module Theseus
  # The Path class is used to represent paths (and, generally, regions) within
  # a maze. Arbitrary metadata can be associated with these paths, as well.
  #
  # Although a Path can be instantiated directly, it is generally more convenient
  # (and less error-prone) to instantiate them via Maze#new_path.
  class Path
    # Represents the exit paths from each cell in the Path. This is a Hash of bitfields,
    # and should be treated as read-only.
    attr_reader :paths

    # Represents the cells within the Path. This is a Hash of bitfields, with bit 1
    # meaning the primary plane for the cell is set for this Path, and bit 2 meaning
    # the under plane for the cell is set.
    attr_reader :cells

    # Instantiates a new plane for the given +maze+ instance, and with the given +meta+
    # data. Initially, the path is empty.
    def initialize(maze, meta={})
      @maze = maze
      @paths = Hash.new(0)
      @cells = Hash.new(0)
      @meta = meta
    end

    # Returns the metadata for the given +key+.
    def [](key)
      @meta[key]
    end

    # Marks the given +point+ as occupied in this path. If +how+ is +:over+, the
    # point is set in the primary plane. Otherwise, it is set in the under plane.
    #
    # The +how+ parameter is usually used in conjunction with the return value of
    # the #link method:
    #
    #   how = path.link(from, to)
    #   path.set(to, how)
    def set(point, how=:over)
      @cells[point] |= (how == :over ? 1 : 2)
    end

    # Creates a link between the two given points. The points must be adjacent.
    # If the corresponding passage in the maze moves into the under plane as it
    # enters +to+, this method returns +:under+. Otherwise, it returns +:over+.
    #
    # If the two points are not adjacent, no link is created.
    def link(from, to)
      if (direction = @maze.relative_direction(from, to))
        opposite = @maze.opposite(direction)

        if @maze.valid?(from[0], from[1])
          direction <<= Maze::UNDER_SHIFT if @maze[from[0], from[1]] & direction == 0
          @paths[from] |= direction
        end

        opposite <<= Maze::UNDER_SHIFT if @maze[to[0], to[1]] & opposite == 0
        @paths[to] |= opposite

        return (opposite & Maze::UNDER == 0) ? :over : :under
      end

      return :over
    end

    # Adds all path and cell information from the parameter (which must be a
    # Path instance) to the current Path object. The metadata from the parameter
    # is not copied.
    def add_path(path)
      path.paths.each do |pt, value|
        @paths[pt] |= value
      end

      path.cells.each do |pt, value|
        @cells[pt] |= value
      end
    end
    
    # Returns true if the given point is occuped in the path, for the given plane.
    # If +how+ is +:over+, the primary plane is queried. Otherwise, the under
    # plane is queried.
    def set?(point, how=:over)
      @cells[point] & (how == :over ? 1 : 2) != 0
    end

    # Returns true if there is a path from the given point, in the given direction.
    def path?(point, direction)
      @paths[point] & direction != 0
    end
  end
end

module Theseus
  # An upsilon maze is one in which the field is tesselated into octogons and
  # squares:
  #
  #    _   _   _   _
  #   / \_/ \_/ \_/ \
  #   | |_| |_| |_| |
  #   \_/ \_/ \_/ \_/
  #   |_| |_| |_| |_|
  #   / \_/ \_/ \_/ \
  #   | |_| |_| |_| |
  #   \_/ \_/ \_/ \_/
  #
  # Upsilon mazes in Theseus support weaving, but not symmetry (yet).
  #
  #   maze = Theseus::UpsilonMaze.generate(width: 10)
  #   puts maze
  class UpsilonMaze < Maze
    def potential_exits_at(x, y) #:nodoc:
      if (x+y) % 2 == 0 # octogon
        [N, S, E, W, NW, NE, SW, SE]
      else # square
        [N, S, E, W]
      end
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction) #:nodoc:
      apply_move_at(to_x, to_y, direction << UNDER_SHIFT)
      apply_move_at(to_x, to_y, opposite(direction) << UNDER_SHIFT)

      nx, ny = move(to_x, to_y, direction)
      [nx, ny, direction]
    end
  end
end
module Theseus
  module Algorithms
    # A minimal abstract superclass for maze algorithms to descend
    # from, mostly as a helper to provide some basic, common
    # functionality.
    class Base
      # The maze object that the algorithm will operate on.
      attr_reader :maze

      # Create a new algorithm object that will operate on the
      # given maze.
      def initialize(maze, options={})
        @maze = maze
        @pending = true
      end

      # Returns true if the algorithm has not yet completed.
      def pending?
        @pending
      end

      # Execute a single step of the algorithm. Return true
      # if the algorithm is still pending, or false if it has
      # completed.
      def step
        return false unless pending?
        do_step
      end
    end
  end
end

module Theseus
  module Algorithms
    # Kruskal's algorithm is a means of finding a minimum spanning tree for a
    # weighted graph. By changing how edges are selected, it becomes suitable
    # for use as a maze generator.
    #
    # The mazes it generates tend to have a lot of short cul-de-sacs, which
    # on the one hand makes the maze look "spiky", but on the other hand
    # can potentially make the maze harder to solve.
    #
    # This implementation of Kruskal's algorithm does not support weave
    # mazes.
    class Kruskal < Base
      class TreeSet #:nodoc:
        attr_accessor :parent

        def initialize
          @parent = nil
        end

        def root
          @parent ? @parent.root : self
        end

        def connected?(tree)
          root == tree.root
        end

        def connect(tree)
          tree.root.parent = self
        end
      end

      def initialize(maze, options={}) #:nodoc:
        super

        if @maze.weave > 0
          raise ArgumentError, "weave mazes cannot be generated with kruskal's algorithm"
        end

        @sets = Array.new(@maze.height) { Array.new(@maze.width) { TreeSet.new } }
        @edges = []

        maze.height.times do |y|
          maze.row_length(y).times do |x|
            next unless @maze.valid?(x, y)
            @maze.potential_exits_at(x, y).each do |dir|
              dx, dy = @maze.dx(dir), @maze.dy(dir)
              if (dx < 0 || dy < 0) && @maze.valid?(x+dx, y+dy)
                weight = rand(100) < @maze.randomness ? 0.5 + rand : 1
                @edges << [x, y, dir, weight]
              end
            end
          end
        end

        @edges = @edges.sort_by { |e| e.last }
      end

      def do_step #:nodoc:
        until @edges.empty?
          x, y, direction, _ = @edges.pop
          nx, ny = x + @maze.dx(direction), y + @maze.dy(direction)

          set1, set2 = @sets[y][x], @sets[ny][nx]
          unless set1.connected?(set2)
            set1.connect(set2)
            @maze.apply_move_at(x, y, direction)
            @maze.apply_move_at(nx, ny, @maze.opposite(direction))
            return true
          end
        end

        @pending = false
        return false
      end
    end
  end
end

module Theseus
  module Algorithms
    # The recursive backtracking algorithm is a quick, flexible algorithm
    # for generating mazes. It tends to produce mazes with fewer dead-ends
    # than algorithms like Kruskal's or Prim's. 
    class RecursiveBacktracker < Base
      # The x-coordinate that the generation algorithm will consider next.
      attr_reader :x

      # The y-coordinate that the generation algorithm will consider next.
      attr_reader :y

      def initialize(maze, options={}) #:nodoc:
        super

        loop do
          @y = rand(@maze.height)
          @x = rand(@maze.row_length(@y))
          break if @maze.valid?(@x, @y)
        end

        @tries = @maze.potential_exits_at(@x, @y).shuffle
        @stack = []
      end

      def do_step #:nodoc:
        direction = next_direction or return false
        nx, ny = @maze.move(@x, @y, direction)

        @maze.apply_move_at(@x, @y, direction)

        # if (nx,ny) is already visited, then we're weaving (moving either over
        # or under the existing passage).
        nx, ny, direction = @maze.perform_weave(@x, @y, nx, ny, direction) if @maze[nx, ny] != 0

        @maze.apply_move_at(nx, ny, @maze.opposite(direction))

        @stack.push([@x, @y, @tries])
        @tries = @maze.potential_exits_at(nx, ny).shuffle
        @tries.push direction if @tries.include?(direction) unless rand(100) < @maze.randomness
        @x, @y = nx, ny

        return true
      end

      private

      # Returns the next direction that ought to be attempted by the recursive
      # backtracker. This will also handle the backtracking. If there are no
      # more directions to attempt, and the stack is empty, this will return +nil+.
      def next_direction #:nodoc:
        loop do
          direction = @tries.pop
          nx, ny = @maze.move(@x, @y, direction)

          if @maze.valid?(nx, ny) && (@maze[@x, @y] & (direction | (direction << Maze::UNDER_SHIFT)) == 0)
            if @maze[nx, ny] == 0
              return direction
            elsif !@maze.dead?(@maze[nx, ny]) && @maze.weave > 0 && rand(100) < @maze.weave
              # see if we can weave over/under the cell at (nx,ny)
              return direction if @maze.weave_allowed?(@x, @y, nx, ny, direction)
            end
          end

          while @tries.empty?
            if @stack.empty?
              @pending = false
              return nil
            else
              @x, @y, @tries = @stack.pop
            end
          end
        end
      end

    end
  end
end

module Theseus
  module Algorithms
    class Prim < Base
      IN       = 0x10000 # indicate that a cell, though blank, is part of the IN set
      FRONTIER = 0x20000 # indicate that a cell is part of the frontier set

      def initialize(maze, options={}) #:nodoc:
        super

        if @maze.weave > 0
          raise ArgumentError, "weave mazes cannot be generated with prim's algorithm"
        end

        @frontier = []

        loop do
          y = rand(@maze.height)
          x = rand(@maze.row_length(y))
          next unless @maze.valid?(x, y)

          mark_cell(x, y)
          break
        end
      end

      # Iterates over each cell in the frontier space, yielding the coordinates
      # of each one.
      def each_frontier
        @frontier.each do |x, y|
          yield x, y
        end
      end

      def do_step #:nodoc:
        if rand(100) < @maze.randomness
          x, y = @frontier.delete_at(rand(@frontier.length))
        else
          x, y = @frontier.pop
        end

        neighbors = find_neighbors_of(x, y)
        direction, nx, ny = neighbors[rand(neighbors.length)]

        @maze.apply_move_at(x, y, direction)
        @maze.apply_move_at(nx, ny, @maze.opposite(direction))

        mark_cell(x, y)

        @pending = @frontier.any?
      end

      private

      def mark_cell(x, y) #:nodoc:
        @maze[x, y] |= IN
        @maze[x, y] &= ~FRONTIER

        @maze.potential_exits_at(x, y).each do |dir|
          nx, ny = x + @maze.dx(dir), y + @maze.dy(dir)
          if @maze.valid?(nx, ny) && @maze[nx, ny] == 0
            @maze[nx, ny] |= FRONTIER
            @frontier << [nx, ny]
          end
        end
      end

      def find_neighbors_of(x, y) #:nodoc:
        list = []

        @maze.potential_exits_at(x, y).each do |dir|
          nx, ny = x + @maze.dx(dir), y + @maze.dy(dir)
          list << [dir, nx, ny] if @maze.valid?(nx,ny) && @maze[nx, ny] & IN != 0
        end

        return list
      end
    end
  end
end

module Theseus
  module Solvers
    # The abstract superclass for solver implementations. It simply provides
    # some helper methods that implementations would otherwise have to duplicate.
    class Base
      # The maze object that this solver will provide a solution for.
      attr_reader :maze

      # The point (2-tuple array) at which the solution path should begin.
      attr_reader :a

      # The point (2-tuple array) at which the solution path should end.
      attr_reader :b

      # Create a new solver instance for the given maze, using the given
      # start (+a+) and finish (+b+) points. The solution will not be immediately
      # generated; to do so, use the #step or #solve methods.
      def initialize(maze, a=maze.start, b=maze.finish)
        @maze = maze
        @a = a
        @b = b
        @solution = nil
      end

      # Returns +true+ if the solution has been generated.
      def solved?
        @solution != nil
      end

      # Returns the solution path as an array of 2-tuples, beginning with #a and
      # ending with #b. If the solution has not yet been generated, this will
      # generate the solution first, and then return it.
      def solution
        solve unless solved?
        @solution
      end

      # Generates the solution to the maze, and returns +self+. If the solution
      # has already been generated, this does nothing.
      def solve
        while !solved?
          step
        end

        self
      end

      # If the maze is solved, this yields each point in the solution, in order.
      #
      # If the maze has not yet been solved, this yields the result of calling
      # #step, until the maze has been solved.
      def each
        if solved?
          solution.each { |s| yield s }
        else
          yield s while s = step
        end
      end

      # Returns the solution (or, if the solution is not yet fully generated,
      # the current_solution) as a Theseus::Path object.
      def to_path(options={})
        path = @maze.new_path(options)
        prev = @maze.entrance

        (@solution || current_solution).each do |pt|
          how = path.link(prev, pt)
          path.set(pt, how)
          prev = pt
        end

        how = path.link(prev, @maze.exit)
        path.set(@maze.exit, how)

        path
      end

      # Returns the current (potentially partial) solution to the maze. This
      # is for use while the algorithm is running, so that the current best-solution
      # may be inspected (or displayed).
      def current_solution
        raise NotImplementedError, "solver subclasses must implement #current_solution"
      end

      # Runs a single iteration of the solution algorithm. Returns +false+ if the
      # algorithm has completed, and non-nil otherwise. The return value is
      # algorithm-dependent.
      def step
        raise NotImplementedError, "solver subclasses must implement #step"
      end
    end
  end
end

module Theseus
  module Solvers
    # An implementation of the A* search algorithm. Although this can be used to
    # search "perfect" mazes (those without loops), the recursive backtracker is
    # more efficient in that case.
    #
    # The A* algorithm really shines, though, with multiply-connected mazes
    # (those with non-zero braid values, or some symmetrical mazes). In this case,
    # it is guaranteed to return the shortest path through the maze between the
    # two points.
    class Astar < Base

      # This is the data structure used by the Astar solver to keep track of the
      # current cost of each examined cell and its associated history (path back
      # to the start).
      #
      # Although you will rarely need to use this class, it is documented because
      # applications that wish to visualize the A* algorithm can use the open set
      # of Node instances to draw paths through the maze as the algorithm runs.
      class Node
        include Comparable

        # The point in the maze associated with this node.
        attr_accessor :point

        # Whether the node is on the primary plane (+false+) or the under plane (+true+)
        attr_accessor :under

        # The path cost of this node (the distance from the start to this cell,
        # through the maze)
        attr_accessor :path_cost
        
        # The (optimistic) estimate for how much further the exit is from this node.
        attr_accessor :estimate
        
        # The total cost associated with this node (path_cost + estimate)
        attr_accessor :cost
        
        # The next node in the linked list for the set that this node belongs to.
        attr_accessor :next

        # The array of points leading from the starting point, to this node.
        attr_reader :history

        def initialize(point, under, path_cost, estimate, history) #:nodoc:
          @point, @under, @path_cost, @estimate = point, under, path_cost, estimate
          @history = history
          @cost = path_cost + estimate
        end

        def <=>(node) #:nodoc:
          cost <=> node.cost
        end
      end

      # The open set. This is a linked list of Node instances, used by the A*
      # algorithm to determine which nodes remain to be considered. It is always
      # in sorted order, with the most likely candidate at the head of the list.
      attr_reader :open

      def initialize(maze, a=maze.start, b=maze.finish) #:nodoc:
        super
        @open = Node.new(@a, false, 0, estimate(@a), [])
        @visits = Array.new(@maze.height) { Array.new(@maze.width, 0) }
      end

      def current_solution #:nodoc:
        @open.history + [@open.point]
      end

      def step #:nodoc:
        return false unless @open

        current = @open

        if current.point == @b
          @open = nil
          @solution = current.history + [@b]
        else
          @open = @open.next

          @visits[current.point[1]][current.point[0]] |= current.under ? 2 : 1

          cell = @maze[current.point[0], current.point[1]]

          directions = @maze.potential_exits_at(current.point[0], current.point[1])
          directions.each do |dir|
            try = current.under ? (dir << Theseus::Maze::UNDER_SHIFT) : dir
            if cell & try != 0
              point = move(current.point, dir)
              next unless @maze.valid?(point[0], point[1])
              under = ((@maze[point[0], point[1]] >> Theseus::Maze::UNDER_SHIFT) & @maze.opposite(dir) != 0)
              add_node(point, under, current.path_cost+1, current.history + [current.point])
            end
          end
        end

        return current
      end

      private

      def estimate(pt) #:nodoc:
        Math.sqrt((@b[0] - pt[0])**2 + (@b[1] - pt[1])**2)
      end

      def add_node(pt, under, path_cost, history) #:nodoc:
        return if @visits[pt[1]][pt[0]] & (under ? 2 : 1) != 0

        node = Node.new(pt, under, path_cost, estimate(pt), history)

        if @open
          p, n = nil, @open

          while n && n < node
            p = n
            n = n.next
          end

          if p.nil?
            node.next = @open
            @open = node
          else
            node.next = n
            p.next = node
          end

          # remove duplicates
          while node.next && node.next.point == node.point
            node.next = node.next.next
          end
        else
          @open = node
        end
      end

      def move(pt, direction) #:nodoc:
        [pt[0] + @maze.dx(direction), pt[1] + @maze.dy(direction)]
      end
    end
  end
end

module Theseus
  module Solvers
    # An implementation of a recursive backtracker for solving a maze. Although it will
    # work (eventually) for multiply-connected mazes, it will almost certainly not
    # return an optimal solution in that case. Thus, this solver is best suited only
    # for "perfect" mazes (those with no loops).
    #
    # For mazes that contain loops, see the Theseus::Solvers::Astar class.
    class Backtracker < Base
      def initialize(maze, a=maze.start, b=maze.finish) #:nodoc:
        super
        @visits = Array.new(@maze.height) { Array.new(@maze.width, 0) }
        @stack = []
      end

      VISIT_MASK = { false => 1, true => 2 }

      def current_solution #:nodoc:
        @stack[1..-1].map { |item| item[0] }
      end

      def step #:nodoc:
        if @stack == [:fail]
          return false
        elsif @stack.empty?
          @stack.push(:fail)
          @stack.push([@a, @maze.potential_exits_at(@a[0], @a[1]).dup])
          return @a.dup
        elsif @stack.last[0] == @b
          @solution = @stack[1..-1].map { |pt, tries| pt }
          return false
        else
          x, y = @stack.last[0]
          cell = @maze[x, y]
          loop do
            try = @stack.last[1].pop

            if try.nil?
              spot = @stack.pop
              x, y = spot[0]
              return :backtrack
            elsif (cell & try) != 0
              # is the current path an "under" path for the current cell (x,y)?
              is_under = (try & Maze::UNDER != 0)

              dir = is_under ? (try >> Maze::UNDER_SHIFT) : try
              opposite = @maze.opposite(dir)

              nx, ny = @maze.move(x, y, dir)

              # is the new path an "under" path for the next cell (nx,ny)?
              going_under = @maze[nx, ny] & (opposite << Maze::UNDER_SHIFT) != 0

              # might be out of bounds, due to the entrance/exit passages
              next if !@maze.valid?(nx, ny) || (@visits[ny][nx] & VISIT_MASK[going_under] != 0)

              @visits[ny][nx] |= VISIT_MASK[going_under]
              ncell = @maze[nx, ny]
              p = [nx, ny]

              if ncell & (opposite << Maze::UNDER_SHIFT) != 0 # underpass
                unders = (ncell & Maze::UNDER) >> Maze::UNDER_SHIFT
                exit_dir = unders & ~opposite
                directions = [exit_dir << Maze::UNDER_SHIFT]
              else
                directions = @maze.potential_exits_at(nx, ny) - [@maze.opposite(dir)]
              end

              @stack.push([p, directions])
              return p.dup
            end
          end
        end
      end
    end
  end
end


module Theseus
  module Formatters
    # This is an abstract superclass for PNG formatters. It simply provides some common
    # utility and drawing methods that subclasses can take advantage of, to render
    # mazes to a PNG canvas.
    #
    # Colors are given as 32-bit integers, with each RGBA component occupying 1 byte.
    # R is the highest byte, A is the lowest byte. In other words, 0xFF0000FF is an
    # opaque red, and 0x7f7f7f7f is a semi-transparent gray. 0x0 is fully transparent.
    #
    # You may also provide the colors as hexadecimal string values, and they will be
    # converted to the corresponding integers.
    class PNG
      # The default options. Note that not all PNG formatters honor all of these options;
      # specifically, +:wall_width+ is not consistently supported across all formatters.
      DEFAULTS = {
        :cell_size      => 10,
        :wall_width     => 1,
        :wall_color     => 0x000000FF,
        :cell_color     => 0xFFFFFFFF,
        :solution_color => 0xFFAFAFFF,
        :background     => 0x00000000,
        :outer_padding  => 2,
        :cell_padding   => 1,
        :solution       => false
      }

      # North, whether in the under or primary plane
      ANY_N = Maze::N | (Maze::N << Maze::UNDER_SHIFT)

      # South, whether in the under or primary plane
      ANY_S = Maze::S | (Maze::S << Maze::UNDER_SHIFT)

      # West, whether in the under or primary plane
      ANY_W = Maze::W | (Maze::W << Maze::UNDER_SHIFT)

      # East, whether in the under or primary plane
      ANY_E = Maze::E | (Maze::E << Maze::UNDER_SHIFT)

      # The options to use for the formatter. These are the ones passed
      # to the constructor, plus the ones from the DEFAULTS hash.
      attr_reader :options

      # The +options+ must be a hash of any of the following options:
      #
      # [:cell_size]      The number of pixels on a side that each cell
      #                   should occupy. Different maze types will use that
      #                   space differently. Also, the cell padding is applied
      #                   inside the cell, and so consumes some of the area.
      #                   The default is 10.
      # [:wall_width]     How thick the walls should be drawn. The default is 1.
      #                   Note that not all PNG formatters will honor this value
      #                   (yet).
      # [:wall_color]     The color to use when drawing the wall. Defaults to black.
      # [:cell_color]     The color to use when drawing the cell. Defaults to white.
      # [:solution_color] The color to use when drawing the solution path. This is
      #                   only used when the :solution option is given.
      # [:background]     The color to use for the background of the maze. Defaults
      #                   to transparent.
      # [:outer_padding]  The extra padding (in pixels) to add around the outside
      #                   edge of the maze. Defaults to 2.
      # [:cell_padding]   The padding (in pixels) to add around the inside of each
      #                   cell. This has the effect of separating the cells. The
      #                   default cell padding is 1.
      # [:solution]       A boolean value indicating whether or not to draw the
      #                   solution path as well. The default is false.
      def initialize(maze, options)
        @options = DEFAULTS.merge(options)

        [:background, :wall_color, :cell_color, :solution_color].each do |c|
          @options[c] = ChunkyPNG::Color.from_hex(@options[c]) if String === @options[c]
        end

        @paths = @options[:paths] || []

        if @options[:solution]
          path = maze.new_solver(type: @options[:solution]).solve.to_path(color: @options[:solution_color])
          @paths = [path, *@paths]
        end
      end

      # Returns the raw PNG data for the formatter.
      def to_blob
        @blob
      end

      # Returns the color at the given point by considering all provided paths. The
      # +:color: metadata from the first path that is set at the given point is
      # returned. If no path describes the given point, then the value of the
      # +:cell_color+ option is returned.
      def color_at(pt, direction=nil)
        @paths.each do |path|
          return path[:color] if direction ? path.path?(pt, direction) : path.set?(pt)
        end

        return @options[:cell_color]
      end

      # Returns a new 2-tuple (x2,y2), where x2 is point[0] + dx, and y2 is point[1] + dy.
      def move(point, dx, dy)
        [point[0] + dx, point[1] + dy]
      end

      # Clamps the value +x+ so that it lies between +low+ and +hi+. In other words,
      # returns +low+ if +x+ is less than +low+, and +high+ if +x+ is greater than
      # +high+, and returns +x+ otherwise.
      def clamp(x, low, hi)
        x = low if x < low
        x = hi  if x > hi
        return x
      end

      # Draws a line from +p1+ to +p2+ on the given canvas object, in the given
      # color. The coordinates of the given points are clamped (naively) to lie
      # within the canvas' bounds.
      def line(canvas, p1, p2, color)
        canvas.line(
          clamp(p1[0].floor, 0, canvas.width-1),
          clamp(p1[1].floor, 0, canvas.height-1),
          clamp(p2[0].floor, 0, canvas.width-1),
          clamp(p2[1].floor, 0, canvas.height-1),
          color)
      end

      # Fills the rectangle defined by the given coordinates with the given color.
      # The coordinates are clamped to lie within the canvas' bounds.
      def fill_rect(canvas, x0, y0, x1, y1, color)
        x0 = clamp(x0, 0, canvas.width-1).floor
        y0 = clamp(y0, 0, canvas.height-1).floor
        x1 = clamp(x1, 0, canvas.width-1).floor
        y1 = clamp(y1, 0, canvas.height-1).floor
        canvas.rect(x0, y0, x1, y1, color, color)
      end

      # Fills the polygon defined by the +points+ array, with the given +color+.
      # Each element of +points+ must be a 2-tuple describing a vertex of the
      # polygon. It is assumed that the polygon is closed. All points are
      # clamped (naively) to lie within the canvas' bounds.
      def fill_poly(canvas, points, color)
        clamped = points.map do |(x, y)|
          [ clamp(x.floor, 0, canvas.width - 1),
            clamp(y.floor, 0, canvas.height - 1) ]
        end

        canvas.polygon(clamped, color, color)
      end
    end
  end
end

module Theseus
  module Formatters
    class PNG
      # Renders a UpsilonMaze to a PNG canvas. Does not currently support the
      # +:wall_width+ option.
      #
      # You will almost never access this class directly. Instead, use
      # UpsilonMaze#to(:png, options) to return the raw PNG data directly.
      class Upsilon < PNG
        # Create and return a fully initialized PNG::Upsilon object, with the
        # maze rendered. To get the maze data, call #to_blob.
        #
        # See Theseus::Formatters::PNG for a list of all supported options.
        def initialize(maze, options={})
          super

          width = @options[:outer_padding] * 2 + (3 * maze.width + 1) * @options[:cell_size] / 4
          height = @options[:outer_padding] * 2 + (3 * maze.height + 1) * @options[:cell_size] / 4

          canvas = ChunkyPNG::Image.new(width, height, @options[:background])

          metrics = { size: @options[:cell_size] - @options[:cell_padding] * 2 }
          metrics[:s4] = metrics[:size] / 4.0
          metrics[:inc] = 3 * @options[:cell_size] / 4.0

          maze.height.times do |y|
            py = @options[:outer_padding] + y * metrics[:inc]
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = @options[:outer_padding] + x * metrics[:inc]

              if (y + x) % 2 == 0
                draw_octogon_cell(canvas, [x, y], px, py, cell, metrics)
              else
                draw_square_cell(canvas, [x, y], px, py, cell, metrics)
              end
            end
          end

          @blob = canvas.to_blob
        end

        private

        def draw_octogon_cell(canvas, point, x, y, cell, metrics) #:nodoc:
          p1 = [x + options[:cell_padding] + metrics[:s4], y + options[:cell_padding]]
          p2 = [x + options[:cell_size] - options[:cell_padding] - metrics[:s4], p1[1]]
          p3 = [x + options[:cell_size] - options[:cell_padding], y + options[:cell_padding] + metrics[:s4]]
          p4 = [p3[0], y + options[:cell_size] - options[:cell_padding] - metrics[:s4]]
          p5 = [p2[0], y + options[:cell_size] - options[:cell_padding]]
          p6 = [p1[0], p5[1]]
          p7 = [x + options[:cell_padding], p4[1]]
          p8 = [p7[0], p3[1]]

          fill_poly(canvas, [p1, p2, p3, p4, p5, p6, p7, p8], color_at(point))

          any = proc { |x| x | (x << Maze::UNDER_SHIFT) }

          if cell & any[Maze::NE] != 0
            far_p6 = move(p6, metrics[:inc], -metrics[:inc])
            far_p7 = move(p7, metrics[:inc], -metrics[:inc])
            fill_poly(canvas, [p2, far_p7, far_p6, p3], color_at(point, any[Maze::NE]))
            line(canvas, p2, far_p7, options[:wall_color])
            line(canvas, p3, far_p6, options[:wall_color])
          end

          if cell & any[Maze::E] != 0
            edge = (x + options[:cell_size] + options[:cell_padding] > canvas.width)
            r1, r2 = p3, edge ? move(p4, options[:cell_padding], 0) : move(p7, options[:cell_size], 0)
            fill_rect(canvas, r1[0], r1[1], r2[0], r2[1], color_at(point, any[Maze::E]))
            line(canvas, r1, [r2[0], r1[1]], options[:wall_color])
            line(canvas, r2, [r1[0], r2[1]], options[:wall_color])
          end

          if cell & any[Maze::SE] != 0
            far_p1 = move(p1, metrics[:inc], metrics[:inc])
            far_p8 = move(p8, metrics[:inc], metrics[:inc])
            fill_poly(canvas, [p4, far_p1, far_p8, p5], color_at(point, any[Maze::SE]))
            line(canvas, p4, far_p1, options[:wall_color])
            line(canvas, p5, far_p8, options[:wall_color])
          end

          if cell & any[Maze::S] != 0
            r1, r2 = p6, move(p2, 0, options[:cell_size])
            fill_rect(canvas, r1[0], r1[1], r2[0], r2[1], color_at(point, any[Maze::S]))
            line(canvas, r1, [r1[0], r2[1]], options[:wall_color])
            line(canvas, r2, [r2[0], r1[1]], options[:wall_color])
          end

          line(canvas, p1, p2, options[:wall_color]) if cell & Maze::N == 0
          line(canvas, p2, p3, options[:wall_color]) if cell & Maze::NE == 0
          line(canvas, p3, p4, options[:wall_color]) if cell & Maze::E == 0
          line(canvas, p4, p5, options[:wall_color]) if cell & Maze::SE == 0
          line(canvas, p5, p6, options[:wall_color]) if cell & Maze::S == 0
          line(canvas, p6, p7, options[:wall_color]) if cell & Maze::SW == 0
          line(canvas, p7, p8, options[:wall_color]) if cell & Maze::W == 0
          line(canvas, p8, p1, options[:wall_color]) if cell & Maze::NW == 0
        end

        def draw_square_cell(canvas, point, x, y, cell, metrics) #:nodoc:
          v = options[:cell_padding] + metrics[:s4]
          p1 = [x + v, y + v]
          p2 = [x + options[:cell_size] - v, y + options[:cell_size] - v]

          fill_rect(canvas, p1[0], p1[1], p2[0], p2[1], color_at(point))

          any = proc { |x| x | (x << Maze::UNDER_SHIFT) }

          if cell & any[Maze::E] != 0
            r1 = [p2[0], p1[1]]
            r2 = [x + metrics[:inc] + v, p2[1]]
            fill_rect(canvas, r1[0], r1[1], r2[0], r2[1], color_at(point, any[Maze::E]))
            line(canvas, r1, [r2[0], r1[1]], options[:wall_color])
            line(canvas, [r1[0], r2[1]], r2, options[:wall_color])
          end

          if cell & any[Maze::S] != 0
            r1 = [p1[0], p2[1]]
            r2 = [p2[0], y + metrics[:inc] + v]
            fill_rect(canvas, r1[0], r1[1], r2[0], r2[1], color_at(point, any[Maze::S]))
            line(canvas, r1, [r1[0], r2[1]], options[:wall_color])
            line(canvas, [r2[0], r1[1]], r2, options[:wall_color])
          end

          line(canvas, p1, [p2[0], p1[1]], options[:wall_color]) if cell & Maze::N == 0
          line(canvas, [p2[0], p1[1]], p2, options[:wall_color]) if cell & Maze::E == 0
          line(canvas, [p1[0], p2[1]], p2, options[:wall_color]) if cell & Maze::S == 0
          line(canvas, p1, [p1[0], p2[1]], options[:wall_color]) if cell & Maze::W == 0
        end
      end
    end
  end
end

module Theseus
  module Formatters
    class PNG
      # Renders an OrthogonalMaze to a PNG canvas.
      #
      # You will almost never access this class directly. Instead, use
      # OrthogonalMaze#to(:png, options) to return the raw PNG data directly.
      class Orthogonal < PNG
        # Create and return a fully initialized PNG::Orthogonal object, with the
        # maze rendered. To get the maze data, call #to_blob.
        #
        # See Theseus::Formatters::PNG for a list of all supported options.
        def initialize(maze, options={})
          super

          width  = @options[:outer_padding] * 2 + maze.width * @options[:cell_size]
          height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size]
          
          canvas = ChunkyPNG::Image.new(width, height, @options[:background])

          @d1 = @options[:cell_padding]
          @d2 = @options[:cell_size] - @options[:cell_padding]
          @w1 = (@options[:wall_width] / 2.0).floor
          @w2 = ((@options[:wall_width] - 1) / 2.0).floor

          maze.height.times do |y|
            py = @options[:outer_padding] + y * @options[:cell_size]
            maze.width.times do |x|
              px = @options[:outer_padding] + x * @options[:cell_size]
              draw_cell(canvas, [x, y], px, py, maze[x, y])
            end
          end

          @blob = canvas.to_blob
        end

        private

        def draw_cell(canvas, point, x, y, cell) #:nodoc:
          return if cell == 0

          fill_rect(canvas, x + @d1, y + @d1, x + @d2, y + @d2, color_at(point))

          north = cell & Maze::N == Maze::N
          north_under = (cell >> Maze::UNDER_SHIFT) & Maze::N == Maze::N
          south = cell & Maze::S == Maze::S
          south_under = (cell >> Maze::UNDER_SHIFT) & Maze::S == Maze::S
          west = cell & Maze::W == Maze::W
          west_under = (cell >> Maze::UNDER_SHIFT) & Maze::W == Maze::W
          east = cell & Maze::E == Maze::E
          east_under = (cell >> Maze::UNDER_SHIFT) & Maze::E == Maze::E

          draw_vertical(canvas, x, y, 1, north || north_under, !north || north_under, color_at(point, ANY_N))
          draw_vertical(canvas, x, y + options[:cell_size], -1, south || south_under, !south || south_under, color_at(point, ANY_S))
          draw_horizontal(canvas, x, y, 1, west || west_under, !west || west_under, color_at(point, ANY_W))
          draw_horizontal(canvas, x + options[:cell_size], y, -1, east || east_under, !east || east_under, color_at(point, ANY_E))
        end

        def draw_vertical(canvas, x, y, direction, corridor, wall, color) #:nodoc:
          if corridor
            fill_rect(canvas, x + @d1, y, x + @d2, y + @d1 * direction, color)
            fill_rect(canvas, x + @d1 - @w1, y - (@w1 * direction), x + @d1 + @w2, y + (@d1 + @w2) * direction, options[:wall_color])
            fill_rect(canvas, x + @d2 - @w2, y - (@w1 * direction), x + @d2 + @w1, y + (@d1 + @w2) * direction, options[:wall_color])
          end

          if wall
            fill_rect(canvas, x + @d1 - @w1, y + (@d1 - @w1) * direction, x + @d2 + @w2, y + (@d1 + @w2) * direction, options[:wall_color])
          end
        end

        def draw_horizontal(canvas, x, y, direction, corridor, wall, color) #:nodoc:
          if corridor
            fill_rect(canvas, x, y + @d1, x + @d1 * direction, y + @d2, color)
            fill_rect(canvas, x - (@w1 * direction), y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d1 + @w2, options[:wall_color])
            fill_rect(canvas, x - (@w1 * direction), y + @d2 - @w2, x + (@d1 + @w2) * direction, y + @d2 + @w1, options[:wall_color])
          end

          if wall
            fill_rect(canvas, x + (@d1 - @w1) * direction, y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d2 + @w2, options[:wall_color])
          end
        end
      end
    end
  end
end

module Theseus
  module Formatters
    class PNG
      # Renders a DeltaMaze to a PNG canvas. Does not currently support the
      # +:wall_width+ option.
      #
      # You will almost never access this class directly. Instead, use
      # DeltaMaze#to(:png, options) to return the raw PNG data directly.
      class Delta < PNG
        # Create and return a fully initialized PNG::Delta object, with the
        # maze rendered. To get the maze data, call #to_blob.
        #
        # See Theseus::Formatters::PNG for a list of all supported options.
        def initialize(maze, options={})
          super

          height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size]
          width = @options[:outer_padding] * 2 + (maze.width + 1) * @options[:cell_size] / 2

          canvas = ChunkyPNG::Image.new(width, height, @options[:background])

          maze.height.times do |y|
            py = @options[:outer_padding] + y * @options[:cell_size]
            maze.row_length(y).times do |x|
              px = @options[:outer_padding] + x * @options[:cell_size] / 2.0
              draw_cell(canvas, [x, y], maze.points_up?(x,y), px, py, maze[x, y])
            end
          end

          @blob = canvas.to_blob
        end

        private

        def draw_cell(canvas, point, up, x, y, cell) #:nodoc:
          return if cell == 0

          p1 = [x + options[:cell_size] / 2.0, up ? (y + options[:cell_padding]) : (y + options[:cell_size] - options[:cell_padding])]
          p2 = [x + options[:cell_padding], up ? (y + options[:cell_size] - options[:cell_padding]) : (y + options[:cell_padding])]
          p3 = [x + options[:cell_size] - options[:cell_padding], p2[1]]

          fill_poly(canvas, [p1, p2, p3], color_at(point))

          if cell & (Maze::N | Maze::S) != 0
            clr = color_at(point, (Maze::N | Maze::S))
            dy = options[:cell_padding]
            sign = (cell & Maze::N != 0) ? -1 : 1
            r1, r2 = p2, move(p3, 0, sign*dy)
            fill_rect(canvas, r1[0].round, r1[1].round, r2[0].round, r2[1].round, clr)
            line(canvas, r1, [r1[0], r2[1]], options[:wall_color])
            line(canvas, r2, [r2[0], r1[1]], options[:wall_color])
          else
            line(canvas, p2, p3, options[:wall_color])
          end

          dx = options[:cell_padding]
          if cell & ANY_W != 0
            r1, r2, r3, r4 = p1, move(p1,-dx,0), move(p2,-dx,0), p2
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, ANY_W))
            line(canvas, r1, r2, options[:wall_color])
            line(canvas, r3, r4, options[:wall_color])
          end

          if cell & Maze::W == 0
            line(canvas, p1, p2, options[:wall_color])
          end

          if cell & ANY_E != 0
            r1, r2, r3, r4 = p1, move(p1,dx,0), move(p3,dx,0), p3
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, ANY_E))
            line(canvas, r1, r2, options[:wall_color])
            line(canvas, r3, r4, options[:wall_color])
          end

          if cell & Maze::E == 0
            line(canvas, p3, p1, options[:wall_color])
          end
        end
      end
    end
  end
end


module Theseus
  module Formatters
    class PNG
      # Renders a SigmaMaze to a PNG canvas. Does not currently support the
      # +:wall_width+ option.
      #
      # You will almost never access this class directly. Instead, use
      # SigmaMaze#to(:png, options) to return the raw PNG data directly.
      class Sigma < PNG
        # Create and return a fully initialized PNG::Sigma object, with the
        # maze rendered. To get the maze data, call #to_blob.
        #
        # See Theseus::Formatters::PNG for a list of all supported options.
        def initialize(maze, options={})
          super

          width = @options[:outer_padding] * 2 + (3 * maze.width + 1) * @options[:cell_size] / 4
          height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size] + @options[:cell_size] / 2

          canvas = ChunkyPNG::Image.new(width, height, @options[:background])

          maze.height.times do |y|
            py = @options[:outer_padding] + y * @options[:cell_size]
            maze.row_length(y).times do |x|
              px = @options[:outer_padding] + x * 3 * @options[:cell_size] / 4.0
              shifted = (x % 2 != 0)
              dy = shifted ? (@options[:cell_size] / 2.0) : 0
              draw_cell(canvas, [x, y], shifted, px, py+dy, maze[x, y])
            end
          end

          @blob = canvas.to_blob
        end

        private

        def draw_cell(canvas, point, shifted, x, y, cell) #:nodoc:
          return if cell == 0

          size = options[:cell_size] - options[:cell_padding] * 2
          s4 = size / 4.0

          fs4 = options[:cell_size] / 4.0 # fs == full-size, without padding

          p1 = [x + options[:cell_padding] + s4, y + options[:cell_padding]]
          p2 = [x + options[:cell_size] - options[:cell_padding] - s4, p1[1]]
          p3 = [x + options[:cell_padding] + size, y + options[:cell_size] / 2.0]
          p4 = [p2[0], y + options[:cell_size] - options[:cell_padding]]
          p5 = [p1[0], p4[1]]
          p6 = [x + options[:cell_padding], p3[1]]

          fill_poly(canvas, [p1, p2, p3, p4, p5, p6], color_at(point))

          n  = Maze::N
          s  = Maze::S
          nw = shifted ? Maze::W : Maze::NW
          ne = shifted ? Maze::E : Maze::NE
          sw = shifted ? Maze::SW : Maze::W
          se = shifted ? Maze::SE : Maze::E

          any = proc { |x| x | (x << Maze::UNDER_SHIFT) }

          if cell & any[s] != 0
            r1, r2 = p5, move(p4, 0, options[:cell_padding]*2)
            fill_rect(canvas, r1[0], r1[1], r2[0], r2[1], color_at(point, any[s]))
            line(canvas, p5, move(p5, 0, options[:cell_padding]*2), options[:wall_color])
            line(canvas, p4, move(p4, 0, options[:cell_padding]*2), options[:wall_color])
          end

          if cell & any[ne] != 0
            ne_x = x + 3 * options[:cell_size] / 4.0
            ne_y = y - options[:cell_size] * 0.5
            ne_p5 = [ne_x + options[:cell_padding] + s4, ne_y + options[:cell_size] - options[:cell_padding]]
            ne_p6 = [ne_x + options[:cell_padding], ne_y + options[:cell_size] * 0.5]
            r1, r2, r3, r4 = p2, p3, ne_p5, ne_p6
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, any[ne]))
            line(canvas, r1, r4, options[:wall_color])
            line(canvas, r2, r3, options[:wall_color])
          end

          if cell & any[se] != 0
            se_x = x + 3 * options[:cell_size] / 4.0
            se_y = y + options[:cell_size] * 0.5
            se_p1 = [se_x + s4 + options[:cell_padding], se_y + options[:cell_padding]]
            se_p6 = [se_x + options[:cell_padding], se_y + options[:cell_size] * 0.5]
            r1, r2, r3, r4 = p3, p4, se_p6, se_p1
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, any[se]))
            line(canvas, r1, r4, options[:wall_color])
            line(canvas, r2, r3, options[:wall_color])
          end

          line(canvas, p1, p2, options[:wall_color]) if cell & n == 0
          line(canvas, p2, p3, options[:wall_color]) if cell & ne == 0
          line(canvas, p3, p4, options[:wall_color]) if cell & se == 0
          line(canvas, p4, p5, options[:wall_color]) if cell & s == 0
          line(canvas, p5, p6, options[:wall_color]) if cell & sw == 0
          line(canvas, p6, p1, options[:wall_color]) if cell & nw == 0
        end
      end
    end
  end
end

module Theseus
  module Formatters
    # ASCII formatters render a maze as ASCII art. The ASCII representation
    # is intended mostly to give you a "quick look" at the maze, and will
    # rarely suffice for showing more than an overview of the maze's shape.
    #
    # This is the abstract superclass of the ASCII formatters, and provides
    # helpers for writing to a textual "canvas".
    class ASCII
      # The width of the canvas. This corresponds to, but is not necessarily the
      # same as, the width of the maze.
      attr_reader :width

      # The height of the canvas. This corresponds to, but is not necessarily the
      # same as, the height of the maze.
      attr_reader :height

      # Create a new ASCII canvas with the given width and height. The canvas is
      # initially blank (set to whitespace).
      def initialize(width, height)
        @width, @height = width, height
        @chars = Array.new(height) { Array.new(width, " ") }
      end

      # Returns the character at the given coordinates.
      def [](x, y)
        @chars[y][x]
      end

      # Sets the character at the given coordinates.
      def []=(x, y, char)
        @chars[y][x] = char
      end

      # Returns the canvas as a multiline string, suitable for displaying.
      def to_s
        @chars.map { |row| row.join }.join("\n")
      end
    end
  end
end

module Theseus
  class CLI
    TYPE_MAP = {
      "ortho"   => Theseus::OrthogonalMaze,
      "delta"   => Theseus::DeltaMaze,
      "sigma"   => Theseus::SigmaMaze,
      "upsilon" => Theseus::UpsilonMaze,
    }

    ALGO_MAP = {
      "backtrack" => Theseus::Algorithms::RecursiveBacktracker,
      "kruskal"   => Theseus::Algorithms::Kruskal,
      "prim"      => Theseus::Algorithms::Prim,
    }

    def self.run(*args)
      new(*args).run
    end

    attr_accessor :animate
    attr_accessor :delay
    attr_accessor :output
    attr_accessor :sparse
    attr_accessor :unicursal
    attr_accessor :type
    attr_accessor :format
    attr_accessor :solution

    attr_reader   :maze_opts
    attr_reader   :png_opts

    def initialize(*args)
      args.flatten!

      @animate = false
      @delay = 50
      @output = "maze"
      @sparse = 0
      @unicursal = false
      @type = "ortho"
      @format = :ascii
      @solution = nil

      @png_opts = Theseus::Formatters::PNG::DEFAULTS.dup
      @maze_opts = { mask: nil, width: nil, height: nil,
        randomness: 50, weave: 0, symmetry: :none, braid: 0, wrap: :none,
        entrance: nil, exit: nil, algorithm: ALGO_MAP["backtrack"] }

      option_parser.parse!(args)

      if args.any?
        abort "extra arguments detected: #{args.inspect}"
      end

      normalize_settings!
    end

    def run
      if @animate
        run_animation
      else
        run_static
      end
    end

    private

    def run_animation
      if format == :ascii
        run_ascii_animation
      else
        run_png_animation
      end
    end

    def clear_screen
      print "\e[2J"
    end

    def cursor_home
      print "\e[H"
    end

    def show_maze
      cursor_home
      puts @maze.to_s(:mode => :unicode)
    end

    def run_ascii_animation
      clear_screen

      @maze.generate! do
        show_maze
        sleep(@delay)
      end

      show_maze
    end

    def write_frame(step, options={})
      f = "%s-%04d.png" % [@output, step]
      step += 1
      File.open(f, "w") { |io| io.write(@maze.to(:png, @png_opts.merge(options))) }
      print "."
    end

    def run_png_animation
      step = 0
      @maze.generate! do
        write_frame(step)
        step += 1
      end

      write_frame(step)
      step += 1

      if @solution
        solver = @maze.new_solver(type: @solution)

        while solver.step
          path = solver.to_path(color: @png_opts[:solution_color])
          write_frame(step, paths: [path])
          step += 1
        end
      end

      puts
      puts "done, %d frames written to %s-*.png" % [step, @output]
    end

    def run_static
      @maze.generate!
      @sparse.times { @maze.sparsify! }

      if @unicursal
        enter_at = @unicursal_entrance || [-1,0]
        if enter_at[0] > 0 && enter_at[0] < width*2
          exit_at = [enter_at[0]+1, enter_at[1]]
        else
          exit_at = [enter_at[0], enter_at[1]+1]
        end
        @maze = @maze.to_unicursal(entrance: enter_at, exit: exit_at)
      end

      if @format == :ascii
        puts @maze.to_s(:mode => :unicode)
      else
        @png_opts[:solution] = @solution
        File.open(@output + ".png", "w") { |io| io.write(@maze.to(:png, @png_opts)) }
        puts "maze written to #{@output}.png"
      end
    end

    def normalize_settings!
      # default width to height, and vice-versa
      @maze_opts[:width] ||= @maze_opts[:height]
      @maze_opts[:height] ||= @maze_opts[:width]

      if @maze_opts[:mask].nil? && (@maze_opts[:width].nil? || @maze_opts[:height].nil?)
        warn "You must specify either a mask (-m) or the maze dimensions(-w or -H)."
        abort "Try --help for a full list of options."
      end

      if @animate
        abort "sparse cannot be used for animated mazes" if @sparse > 0
        abort "cannot animate unicursal mazes" if @unicursal

        if @format != :ascii
          @png_opts[:background] = ChunkyPNG::Color.from_hex(@png_opts[:background]) unless Fixnum === @png_opts[:background]

          if @png_opts[:background] & 0xFF != 0xFF
            warn "if you intend to make a movie out of the frames from the animation,"
            warn "it is HIGHLY RECOMMENDED that you use a fully opaque background color."
          end
        end

        # convert delay to a fraction of a second
        @delay = @delay / 1000.0
      end

      if @solution
        abort "cannot display solution in ascii mode" if @format == :ascii
      end

      if @unicursal
        @unicursal_entrance = @maze_opts.delete(:entrance)
        @maze_opts[:entrance] = [0,0]
        @maze_opts[:exit] = [0,0]
      end

      @maze_opts[:mask] ||= Theseus::TransparentMask.new(@maze_opts[:width], @maze_opts[:height])
      @maze_opts[:width] ||= @maze_opts[:mask].width
      @maze_opts[:height] ||= @maze_opts[:mask].height
      @maze = TYPE_MAP[@type].new(@maze_opts)

      if @unicursal && !@maze.respond_to?(:to_unicursal)
        abort "#{@type} mazes do not support the -u (unicursal) option"
      end
    end

    def option_parser
      OptionParser.new do |opts|
        setup_required_options(opts)
        setup_output_options(opts)
        setup_maze_options(opts)
        setup_formatting_options(opts)
        setup_misc_options(opts)
      end
    end

    def setup_required_options(opts)
      opts.separator ""
      opts.separator "Required options:"

      opts.on("-w", "--width N", Integer, "width of the maze (default 20, or mask width)") do |w|
        @maze_opts[:width] = w
      end

      opts.on("-H", "--height N", Integer, "height of the maze (default 20 or mask height)") do |h|
        @maze_opts[:height] = h
      end

      opts.on("-m", "--mask FILE", "png file to use as mask") do |m|
        case m
        when /^triangle:(\d+)$/ then @maze_opts[:mask] = Theseus::TriangleMask.new($1.to_i)
        else @maze_opts[:mask] = Theseus::Mask.from_png(m)
        end
      end
    end

    def setup_output_options(opts)
      opts.separator ""
      opts.separator "Output options:"

      opts.on("-a", "--[no-]animate", "emit frames for each step") do |v|
        @animate = v
      end

      opts.on("-D", "--delay N", Integer, "time to wait between animation frames, in ms, default is #{@delay}") do |d|
        @delay = d
      end

      opts.on("-o", "--output FILE", "where to save the file(s) (for png only)") do |f|
        @output = f
      end

      opts.on("-f", "--format FMT", "png, ascii (default #{@format})") do |f|
        @format = f.to_sym
      end

      opts.on("-V", "--solve [METHOD]", "whether to display the solution of the maze.", "METHOD is either `backtracker' (the default) or `astar'") do |s|
        @solution = (s || :backtracker).to_sym
      end
    end

    def setup_maze_options(opts)
      opts.separator ""
      opts.separator "Maze options:"

      opts.on("-s", "--seed N", Integer, "random seed to use") do |s|
        srand(s)
      end

      opts.on("-A", "--algorithm NAME", "the algorithm to use to generate the maze.",
                                        "may be any of #{ALGO_MAP.keys.sort.join(",")}.",
                                        "defaults to `backtrack'.") do |a|
        @maze_opts[:algorithm] = ALGO_MAP[a] or abort "unknown algorithm `#{a}'"
      end

      opts.on("-t", "--type TYPE", "#{TYPE_MAP.keys.sort.join(",")} (default: #{@type})") do |t|
        @type = t
      end

      opts.on("-u", "--[no-]unicursal", "generate a unicursal maze (results in 2x size)") do |u|
        @unicursal = u
      end

      opts.on("-y", "--symmetry TYPE", "one of none,x,y,xy,radial (default is '#{@maze_opts[:symmetry]}')") do |s|
        @maze_opts[:symmetry] = s.to_sym
      end

      opts.on("-e", "--weave N", Integer, "0-100, chance of a passage to go over/under another (default #{@maze_opts[:weave]})") do |v|
        @maze_opts[:weave] = v
      end

      opts.on("-r", "--random N", Integer, "0-100, randomness of maze (default #{@maze_opts[:randomness]})") do |r|
        @maze_opts[:randomness] = r
      end

      opts.on("-S", "--sparse N", Integer, "how sparse to make the maze (default #{@sparse})") do |s|
        @sparse = s
      end

      opts.on("-d", "--braid N", Integer, "0-100, percentage of deadends to remove (default #{maze_opts[:braid]})") do |b|
        @maze_opts[:braid] = b
      end

      opts.on("-R", "--wrap axis", "none,x,y,xy (default #{@maze_opts[:wrap]})") do |w|
        @maze_opts[:wrap] = w.to_sym
      end

      opts.on("-E", "--enter [X,Y]", "the entrance of the maze (default -1,0)") do |s|
        @maze_opts[:entrance] = s.split(/,/).map { |v| v.to_i }
      end

      opts.on("-X", "--exit [X,Y]", "the exit of the maze (default width,height-1)") do |s|
        @maze_opts[:exit] = s.split(/,/).map { |v| v.to_i }
      end
    end

    def setup_formatting_options(opts)
      opts.separator ""
      opts.separator "Formatting options:"

      opts.on("-B", "--background COLOR", "rgba hex background color for maze (default %08X)" % @png_opts[:background]) do |c|
        @png_opts[:background] = c
      end

      opts.on("-C", "--cellcolor COLOR", "rgba hex cell color for maze (default %08X)" % @png_opts[:cell_color]) do |c|
        @png_opts[:cell_color] = c
      end

      opts.on("-L", "--wallcolor COLOR", "rgba hex wall color for maze (default %08X)" % @png_opts[:wall_color]) do |c|
        @png_opts[:wall_color] = c
      end

      opts.on("-U", "--solutioncolor COLOR", "rgba hex color for the answer path (default %08X)" % @png_opts[:solution_color]) do |c|
        @png_opts[:solution_color] = c
      end

      opts.on("-c", "--cell N", Integer, "size of each cell (default #{@png_opts[:cell_size]})") do |c|
        @png_opts[:cell_size] = c
      end

      opts.on("-b", "--border N", Integer, "border padding around outside (default #{@png_opts[:outer_padding]})") do |c|
        @png_opts[:outer_padding] = c
      end

      opts.on("-p", "--padding N", Integer, "padding around cell (default #{@png_opts[:cell_padding]})") do |c|
        @png_opts[:cell_padding] = c
      end

      opts.on("-W", "--wall N", Integer, "thickness of walls (default #{@png_opts[:wall_width]})") do |c|
        @png_opts[:wall_width] = c
      end
    end

    def setup_misc_options(opts)
      opts.separator ""
      opts.separator "Other options:"

      opts.on_tail("-v", "--version", "display the Theseus version and exit") do
        maze = Theseus::OrthogonalMaze.generate(width: 20, height: 4)
        s = maze.to_s(mode: :lines).strip
        print s.gsub(/^/, "          ").sub(/^\s*/, "theseus --")

        require 'theseus/version'
        puts "--> v#{Theseus::Version::STRING}"
        puts "a maze generator, renderer, and solver by Jamis Buck <jamis@jamisbuck.org>"
        exit
      end

      opts.on_tail("-h", "--help", "this helpful list of options") do
        puts opts
        exit
      end
    end
  end
end




module Theseus
  # A "mask" is, conceptually, a grid of true/false values that corresponds,
  # one-to-one, with the cells of a maze object. For every mask cell that is true,
  # the corresponding cell in a maze may contain passages. For every mask cell that
  # is false, the corresponding maze cell must be blank.
  #
  # Any object may be used as a mask as long as it responds to #height, #width, and
  # #[].
  class Mask
    # Given a string, treat each line as rows and each character as a cell. Every
    # period character (".") will be mapped to +true+, and everything else to +false+.
    # This lets you define simple masks as ASCII art:
    #
    #   mask_string = <<MASK
    #   ..........
    #   .X....XXX.
    #   ..X....XX.
    #   ...X....X.
    #   ....X.....
    #   .....X....
    #   .X....X...
    #   .XX....X..
    #   .XXX....X.
    #   ..........
    #   MASK
    #
    #   mask = Theseus::Mask.from_text(mask_string)
    #
    def self.from_text(text)
      new(text.strip.split(/\n/).map { |line| line.split(//).map { |c| c == '.' } })
    end

    # Given a PNG file with the given +file_name+, read the file and create a new
    # mask where transparent pixels will be considered +true+, and all others +false+.
    # Note that a pixel with any transparency at all will be considered +true+.
    #
    # The resulting mask will have the same dimensions as the image file.
    def self.from_png(file_name)
      image = ChunkyPNG::Image.from_file(file_name)
      grid = Array.new(image.height) { |y| Array.new(image.width) { |x| (image[x, y] & 0xff) == 0 } }
      new(grid)
    end

    # The number of rows in the mask.
    attr_reader :height

    # the length of the longest row in the mask.
    attr_reader :width

    # Instantiate a new mask from the given grid, which must be an Array of rows, and each
    # row must be an Array of true/false values for each column in the row.
    def initialize(grid)
      @grid = grid
      @height = @grid.length
      @width = @grid.map { |row| row.length }.max
    end

    # Returns the +true+/+false+ value for the corresponding cell in the grid.
    def [](x,y)
      @grid[y][x]
    end
  end

  # This is a specialized mask, intended for use with DeltaMaze instances (although
  # it will work with any maze). This lets you easily create triangular delta mazes.
  #
  #   mask = Theseus::TriangleMask.new(10)
  #   maze = Theseus::DeltaMaze.generate(mask: mask)
  class TriangleMask
    attr_reader :height, :width

    # Returns a new TriangleMask instance with the given height. The width will
    # always be <code>2h+1</code> (where +h+ is the height).
    def initialize(height)
      @height = height
      @width = @height * 2 + 1
      @grid = Array.new(@height) do |y|
        run = y * 2 + 1
        from = @height - y
        to = from + run - 1
        Array.new(@width) do |x| 
          (x >= from && x <= to) ? true : false
        end
      end
    end

    # Returns the +true+/+false+ value for the corresponding cell in the grid.
    def [](x,y)
      @grid[y][x]
    end
  end

  # This is the default mask used by a maze when an explicit mask is not given.
  # It simply reports every cell as available.
  #
  #   mask = Theseus::TransparentMask.new(20, 20)
  #   maze = Theseus::OrthogonalMaze.new(mask: mask)
  class TransparentMask
    attr_reader :width, :height

    def initialize(width=0, height=0)
      @width = width
      @height = height
    end

    # Always returns +true+.
    def [](x,y)
      true
    end
  end
end
