#!/usr/bin/env ruby

#require 'builder/blankslate'



#!/usr/bin/env ruby

# The XChar library is provided courtesy of Sam Ruby (See
# http://intertwingly.net/stories/2005/09/28/xchar.rb)

# --------------------------------------------------------------------

# If the Builder::XChar module is not currently defined, fail on any
# name clashes in standard library classes.

#module Builder
#  def self.check_for_name_collision(klass, method_name, defined_constant=nil)
#    if klass.method_defined?(method_name.to_s)
#      fail RuntimeError,
#	"Name Collision: Method '#{method_name}' is already defined in #{klass}"
#    end
#  end
#end
#
#if ! defined?(Builder::XChar) and ! String.method_defined?(:encode)
#  Builder.check_for_name_collision(String, "to_xs")
#  Builder.check_for_name_collision(Fixnum, "xchr")
#end

######################################################################
module Builder

  ####################################################################
  # XML Character converter, from Sam Ruby:
  # (see http://intertwingly.net/stories/2005/09/28/xchar.rb). 
  #
  module XChar # :nodoc:

    # See
    # http://intertwingly.net/stories/2004/04/14/i18n.html#CleaningWindows
    # for details.
    CP1252 = {			# :nodoc:
      128 => 8364,		# euro sign
      130 => 8218,		# single low-9 quotation mark
      131 =>  402,		# latin small letter f with hook
      132 => 8222,		# double low-9 quotation mark
      133 => 8230,		# horizontal ellipsis
      134 => 8224,		# dagger
      135 => 8225,		# double dagger
      136 =>  710,		# modifier letter circumflex accent
      137 => 8240,		# per mille sign
      138 =>  352,		# latin capital letter s with caron
      139 => 8249,		# single left-pointing angle quotation mark
      140 =>  338,		# latin capital ligature oe
      142 =>  381,		# latin capital letter z with caron
      145 => 8216,		# left single quotation mark
      146 => 8217,		# right single quotation mark
      147 => 8220,		# left double quotation mark
      148 => 8221,		# right double quotation mark
      149 => 8226,		# bullet
      150 => 8211,		# en dash
      151 => 8212,		# em dash
      152 =>  732,		# small tilde
      153 => 8482,		# trade mark sign
      154 =>  353,		# latin small letter s with caron
      155 => 8250,		# single right-pointing angle quotation mark
      156 =>  339,		# latin small ligature oe
      158 =>  382,		# latin small letter z with caron
      159 =>  376,		# latin capital letter y with diaeresis
    }

    # See http://www.w3.org/TR/REC-xml/#dt-chardata for details.
    PREDEFINED = {
      38 => '&amp;',		# ampersand
      60 => '&lt;',		# left angle bracket
      62 => '&gt;',		# right angle bracket
    }

    # See http://www.w3.org/TR/REC-xml/#charsets for details.
    VALID = [
      0x9, 0xA, 0xD,
      (0x20..0xD7FF), 
      (0xE000..0xFFFD),
      (0x10000..0x10FFFF)
    ]

    # http://www.fileformat.info/info/unicode/char/fffd/index.htm
    REPLACEMENT_CHAR =
      if String.method_defined?(:encode)
        "\uFFFD"
      elsif $KCODE == 'UTF8'
        "\xEF\xBF\xBD"
      else
        '*'
      end
  end

end


if String.method_defined?(:encode)
  module Builder
    module XChar # :nodoc:
      CP1252_DIFFERENCES, UNICODE_EQUIVALENT = Builder::XChar::CP1252.each.
        inject([[],[]]) {|(domain,range),(key,value)|
          [domain << key,range << value]
        }.map {|seq| seq.pack('U*').force_encoding('utf-8')}
  
      XML_PREDEFINED = Regexp.new('[' +
        Builder::XChar::PREDEFINED.keys.pack('U*').force_encoding('utf-8') +
      ']')
  
      INVALID_XML_CHAR = Regexp.new('[^'+
        Builder::XChar::VALID.map { |item|
          case item
          when Fixnum
            [item].pack('U').force_encoding('utf-8')
          when Range
            [item.first, '-'.ord, item.last].pack('UUU').force_encoding('utf-8')
          end
        }.join +
      ']')
  
      ENCODING_BINARY = Encoding.find('BINARY')
      ENCODING_UTF8   = Encoding.find('UTF-8')
      ENCODING_ISO1   = Encoding.find('ISO-8859-1')

      # convert a string to valid UTF-8, compensating for a number of
      # common errors.
      def XChar.unicode(string)
        if string.encoding == ENCODING_BINARY
          if string.ascii_only?
            string
          else
            string = string.clone.force_encoding(ENCODING_UTF8)
            if string.valid_encoding?
              string
            else
              string.encode(ENCODING_UTF8, ENCODING_ISO1)
            end
          end

        elsif string.encoding == ENCODING_UTF8
          if string.valid_encoding?
            string
          else
            string.encode(ENCODING_UTF8, ENCODING_ISO1)
          end

        else
          string.encode(ENCODING_UTF8)
        end
      end

      # encode a string per XML rules
      def XChar.encode(string)
        unicode(string).
          tr(CP1252_DIFFERENCES, UNICODE_EQUIVALENT).
          gsub(INVALID_XML_CHAR, REPLACEMENT_CHAR).
          gsub(XML_PREDEFINED) {|c| PREDEFINED[c.ord]}
      end
    end
  end

else

  ######################################################################
  # Enhance the Fixnum class with a XML escaped character conversion.
  #
  class Fixnum
    XChar = Builder::XChar #if ! defined?(XChar)
  
    # XML escaped version of chr. When <tt>escape</tt> is set to false
    # the CP1252 fix is still applied but utf-8 characters are not
    # converted to character entities.
    def xchr(escape=true)
      n = XChar::CP1252[self] || self
      case n when *XChar::VALID
        XChar::PREDEFINED[n] or 
          (n<128 ? n.chr : (escape ? "&##{n};" : [n].pack('U*')))
      else
        Builder::XChar::REPLACEMENT_CHAR
      end
    end
  end
  

  ######################################################################
  # Enhance the String class with a XML escaped character version of
  # to_s.
  #
  class String
    # XML escaped version of to_s. When <tt>escape</tt> is set to false
    # the CP1252 fix is still applied but utf-8 characters are not
    # converted to character entities.
    def to_xs(escape=true)
      unpack('U*').map {|n| n.xchr(escape)}.join # ASCII, UTF-8
    rescue
      unpack('C*').map {|n| n.xchr}.join # ISO-8859-1, WIN-1252
    end
  end
end


module Builder

  # Generic error for builder
  class IllegalBlockError < RuntimeError; end

  # XmlBase is a base class for building XML builders.  See
  # Builder::XmlMarkup and Builder::XmlEvents for examples.
  class XmlBase #< BlankSlate

    class << self
      attr_accessor :cache_method_calls
    end

    # Create an XML markup builder.
    #
    # out      :: Object receiving the markup.  +out+ must respond to
    #             <tt><<</tt>.
    # indent   :: Number of spaces used for indentation (0 implies no
    #             indentation and no line breaks).
    # initial  :: Level of initial indentation.
    # encoding :: When <tt>encoding</tt> and $KCODE are set to 'utf-8'
    #             characters aren't converted to character entities in
    #             the output stream.
    def initialize(indent=0, initial=0, encoding='utf-8')
      @indent = indent
      @level  = initial
      @encoding = encoding.downcase
    end

    def explicit_nil_handling?
      @explicit_nil_handling
    end

    # Create a tag named +sym+.  Other than the first argument which
    # is the tag name, the arguments are the same as the tags
    # implemented via <tt>method_missing</tt>.
    def tag!(sym, *args, &block)
      text = nil
      attrs = nil
      sym = "#{sym}:#{args.shift}" if args.first.kind_of?(::Symbol)
      sym = sym.to_sym unless sym.class == ::Symbol
      args.each do |arg|
        case arg
        when ::Hash
          attrs ||= {}
          attrs.merge!(arg)
      #log!(:argjasasas, arg, attrs)
        when nil
          attrs ||= {}
          attrs.merge!({:nil => true}) if explicit_nil_handling?
        else
      #log!(:argarg, arg)
          text ||= ''
          text << arg.to_s
        end
      end
      if block
        unless text.nil?
          ::Kernel::raise ::ArgumentError,
            "XmlMarkup cannot mix a text argument with a block"
        end
        _indent
        _start_tag(sym, attrs)
        _newline
        begin
          _nested_structures(block)
        ensure
          _indent
          _end_tag(sym)
          _newline
        end
      elsif text.nil?
        _indent
        _start_tag(sym, attrs, true)
        _newline
      else
        _indent
        _start_tag(sym, attrs)
        text! text
        _end_tag(sym)
        _newline
      end
      @target
    end

    # Create XML markup based on the name of the method.  This method
    # is never invoked directly, but is called for each markup method
    # in the markup block that isn't cached.
    def method_missing(sym, *args, &block)
      cache_method_call(sym) if ::Builder::XmlBase.cache_method_calls
      tag!(sym, *args, &block)
    end

    # Append text to the output target.  Escape any markup.  May be
    # used within the markup brackets as:
    #
    #   builder.p { |b| b.br; b.text! "HI" }   #=>  <p><br/>HI</p>
    def text!(text)
      _text(_escape(text))
    end

    # Append text to the output target without escaping any markup.
    # May be used within the markup brackets as:
    #
    #   builder.p { |x| x << "<br/>HI" }   #=>  <p><br/>HI</p>
    #
    # This is useful when using non-builder enabled software that
    # generates strings.  Just insert the string directly into the
    # builder without changing the inserted markup.
    #
    # It is also useful for stacking builder objects.  Builders only
    # use <tt><<</tt> to append to the target, so by supporting this
    # method/operation builders can use other builders as their
    # targets.
    def <<(text)
      _text(text)
    end

    # For some reason, nil? is sent to the XmlMarkup object.  If nil?
    # is not defined and method_missing is invoked, some strange kind
    # of recursion happens.  Since nil? won't ever be an XML tag, it
    # is pretty safe to define it here. (Note: this is an example of
    # cargo cult programming,
    # cf. http://fishbowl.pastiche.org/2004/10/13/cargo_cult_programming).
    def nil?
      false
    end

    private

    #require 'builder/xchar'
    if ::String.method_defined?(:encode)
      def _escape(text)
        result = XChar.encode(text)
        begin
          encoding = ::Encoding::find(@encoding)
          raise Exception if encoding.dummy?
          result.encode(encoding)
        rescue
          # if the encoding can't be supported, use numeric character references
          result.
            gsub(/[^\u0000-\u007F]/) {|c| "&##{c.ord};"}.
            force_encoding('ascii')
        end
      end
    else
      #TODO
      def _escape(text)
        #if (text.method(:to_xs).arity == 0)
          text.to_xs
        #else
        #  text.to_xs((@encoding != 'utf-8' or $KCODE != 'UTF8'))
        #end
        #text.unpack('U*').map {|n| n.xchr(escape)}.join
        #"cheese"
      end
    end

    def _escape_attribute(text)
      #log!(:escappapa, text, _escape(text))
      _escape(text)
      #.gsub("\n", "&#10;").gsub("\r", "&#13;").
      #  gsub(%r{"}, '&quot;') # " WART
    end

    def _newline
      return if @indent == 0
      text! "\n"
    end

    def _indent
      return if @indent == 0 || @level == 0
      text!(" " * (@level * @indent))
    end

    def _nested_structures(block)
      @level += 1
      block.call(self)
    ensure
      @level -= 1
    end

    # If XmlBase.cache_method_calls = true, we dynamicly create the method
    # missed as an instance method on the XMLBase object. Because XML
    # documents are usually very repetative in nature, the next node will
    # be handled by the new method instead of method_missing. As
    # method_missing is very slow, this speeds up document generation
    # significantly.
    def cache_method_call(sym)
      class << self; self; end.class_eval do
        unless method_defined?(sym)
          define_method(sym) do |*args, &block|
            tag!(sym, *args, &block)
          end
        end
      end
    end
  end

  XmlBase.cache_method_calls = true

end

#--
# Copyright 2004, 2005 by Jim Weirich (jim@weirichhouse.org).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

# Provide a flexible and easy to use Builder for creating XML markup.
# See XmlBuilder for usage details.

#require 'builder/xmlbase'

module Builder

  # Create XML markup easily.  All (well, almost all) methods sent to
  # an XmlMarkup object will be translated to the equivalent XML
  # markup.  Any method with a block will be treated as an XML markup
  # tag with nested markup in the block.
  #
  # Examples will demonstrate this easier than words.  In the
  # following, +xm+ is an +XmlMarkup+ object.
  #
  #   xm.em("emphasized")            # => <em>emphasized</em>
  #   xm.em { xm.b("emp & bold") }   # => <em><b>emph &amp; bold</b></em>
  #   xm.a("A Link", "href"=>"http://onestepback.org")
  #                                  # => <a href="http://onestepback.org">A Link</a>
  #   xm.div { xm.br }               # => <div><br/></div>
  #   xm.target("name"=>"compile", "option"=>"fast")
  #                                  # => <target option="fast" name="compile"\>
  #                                  # NOTE: order of attributes is not specified.
  #
  #   xm.instruct!                   # <?xml version="1.0" encoding="UTF-8"?>
  #   xm.html {                      # <html>
  #     xm.head {                    #   <head>
  #       xm.title("History")        #     <title>History</title>
  #     }                            #   </head>
  #     xm.body {                    #   <body>
  #       xm.comment! "HI"           #     <!-- HI -->
  #       xm.h1("Header")            #     <h1>Header</h1>
  #       xm.p("paragraph")          #     <p>paragraph</p>
  #     }                            #   </body>
  #   }                              # </html>
  #
  # == Notes:
  #
  # * The order that attributes are inserted in markup tags is
  #   undefined.
  #
  # * Sometimes you wish to insert text without enclosing tags.  Use
  #   the <tt>text!</tt> method to accomplish this.
  #
  #   Example:
  #
  #     xm.div {                          # <div>
  #       xm.text! "line"; xm.br          #   line<br/>
  #       xm.text! "another line"; xmbr   #    another line<br/>
  #     }                                 # </div>
  #
  # * The special XML characters <, >, and & are converted to &lt;,
  #   &gt; and &amp; automatically.  Use the <tt><<</tt> operation to
  #   insert text without modification.
  #
  # * Sometimes tags use special characters not allowed in ruby
  #   identifiers.  Use the <tt>tag!</tt> method to handle these
  #   cases.
  #
  #   Example:
  #
  #     xml.tag!("SOAP:Envelope") { ... }
  #
  #   will produce ...
  #
  #     <SOAP:Envelope> ... </SOAP:Envelope>"
  #
  #   <tt>tag!</tt> will also take text and attribute arguments (after
  #   the tag name) like normal markup methods.  (But see the next
  #   bullet item for a better way to handle XML namespaces).
  #
  # * Direct support for XML namespaces is now available.  If the
  #   first argument to a tag call is a symbol, it will be joined to
  #   the tag to produce a namespace:tag combination.  It is easier to
  #   show this than describe it.
  #
  #     xml.SOAP :Envelope do ... end
  #
  #   Just put a space before the colon in a namespace to produce the
  #   right form for builder (e.g. "<tt>SOAP:Envelope</tt>" =>
  #   "<tt>xml.SOAP :Envelope</tt>")
  #
  # * XmlMarkup builds the markup in any object (called a _target_)
  #   that accepts the <tt><<</tt> method.  If no target is given,
  #   then XmlMarkup defaults to a string target.
  #
  #   Examples:
  #
  #     xm = Builder::XmlMarkup.new
  #     result = xm.title("yada")
  #     # result is a string containing the markup.
  #
  #     buffer = ""
  #     xm = Builder::XmlMarkup.new(buffer)
  #     # The markup is appended to buffer (using <<)
  #
  #     xm = Builder::XmlMarkup.new(STDOUT)
  #     # The markup is written to STDOUT (using <<)
  #
  #     xm = Builder::XmlMarkup.new
  #     x2 = Builder::XmlMarkup.new(:target=>xm)
  #     # Markup written to +x2+ will be send to +xm+.
  #
  # * Indentation is enabled by providing the number of spaces to
  #   indent for each level as a second argument to XmlBuilder.new.
  #   Initial indentation may be specified using a third parameter.
  #
  #   Example:
  #
  #     xm = Builder.new(:indent=>2)
  #     # xm will produce nicely formatted and indented XML.
  #
  #     xm = Builder.new(:indent=>2, :margin=>4)
  #     # xm will produce nicely formatted and indented XML with 2
  #     # spaces per indent and an over all indentation level of 4.
  #
  #     builder = Builder::XmlMarkup.new(:target=>$stdout, :indent=>2)
  #     builder.name { |b| b.first("Jim"); b.last("Weirich) }
  #     # prints:
  #     #     <name>
  #     #       <first>Jim</first>
  #     #       <last>Weirich</last>
  #     #     </name>
  #
  # * The instance_eval implementation which forces self to refer to
  #   the message receiver as self is now obsolete.  We now use normal
  #   block calls to execute the markup block.  This means that all
  #   markup methods must now be explicitly send to the xml builder.
  #   For instance, instead of
  #
  #      xml.div { strong("text") }
  #
  #   you need to write:
  #
  #      xml.div { xml.strong("text") }
  #
  #   Although more verbose, the subtle change in semantics within the
  #   block was found to be prone to error.  To make this change a
  #   little less cumbersome, the markup block now gets the markup
  #   object sent as an argument, allowing you to use a shorter alias
  #   within the block.
  #
  #   For example:
  #
  #     xml_builder = Builder::XmlMarkup.new
  #     xml_builder.div { |xml|
  #       xml.stong("text")
  #     }
  #
  class XmlMarkup < XmlBase

    # Create an XML markup builder.  Parameters are specified by an
    # option hash.
    #
    # :target => <em>target_object</em>::
    #    Object receiving the markup.  +target_object+ must respond to
    #    the <tt><<(<em>a_string</em>)</tt> operator and return
    #    itself.  The default target is a plain string target.
    #
    # :indent => <em>indentation</em>::
    #    Number of spaces used for indentation.  The default is no
    #    indentation and no line breaks.
    #
    # :margin => <em>initial_indentation_level</em>::
    #    Amount of initial indentation (specified in levels, not
    #    spaces).
    #
    # :quote => <em>:single</em>::
    #    Use single quotes for attributes rather than double quotes.
    #
    # :escape_attrs => <em>OBSOLETE</em>::
    #    The :escape_attrs option is no longer supported by builder
    #    (and will be quietly ignored).  String attribute values are
    #    now automatically escaped.  If you need unescaped attribute
    #    values (perhaps you are using entities in the attribute
    #    values), then give the value as a Symbol.  This allows much
    #    finer control over escaping attribute values.
    #
    def initialize(options={})
      indent = options[:indent] || 0
      margin = options[:margin] || 0
      @quote = (options[:quote] == :single) ? "'" : '"'
      @explicit_nil_handling = options[:explicit_nil_handling]
      super(indent, margin)
      @target = options[:target] || ""
    end

    # Return the target of the builder.
    def target!
      @target
    end

    def comment!(comment_text)
      _ensure_no_block ::Kernel::block_given?
      _special("<!-- ", " -->", comment_text, nil)
    end

    # Insert an XML declaration into the XML markup.
    #
    # For example:
    #
    #   xml.declare! :ELEMENT, :blah, "yada"
    #       # => <!ELEMENT blah "yada">
    def declare!(inst, *args, &block)
      _indent
      @target << "<!#{inst}"
      args.each do |arg|
        case arg
        when ::String
          @target << %{ "#{arg}"} # " WART
        when ::Symbol
          @target << " #{arg}"
        end
      end
      if ::Kernel::block_given?
        @target << " ["
        _newline
        _nested_structures(block)
        @target << "]"
      end
      @target << ">"
      _newline
    end

    # Insert a processing instruction into the XML markup.  E.g.
    #
    # For example:
    #
    #    xml.instruct!
    #        #=> <?xml version="1.0" encoding="UTF-8"?>
    #    xml.instruct! :aaa, :bbb=>"ccc"
    #        #=> <?aaa bbb="ccc"?>
    #
    # Note: If the encoding is setup to "UTF-8" and the value of
    # $KCODE is "UTF8", then builder will emit UTF-8 encoded strings
    # rather than the entity encoding normally used.
    def instruct!(directive_tag=:xml, attrs={})
      _ensure_no_block ::Kernel::block_given?
      if directive_tag == :xml
        a = { :version=>"1.0", :encoding=>"UTF-8" }
        attrs = a.merge attrs
	@encoding = attrs[:encoding].downcase
      end
      _special(
        "<?#{directive_tag}",
        "?>",
        nil,
        attrs,
        [:version, :encoding, :standalone])
    end

    # Insert a CDATA section into the XML markup.
    #
    # For example:
    #
    #    xml.cdata!("text to be included in cdata")
    #        #=> <![CDATA[text to be included in cdata]]>
    #
    def cdata!(text)
      _ensure_no_block ::Kernel::block_given?
      _special("<![CDATA[", "]]>", text.gsub(']]>', ']]]]><![CDATA[>'), nil)
    end

    private

    # NOTE: All private methods of a builder object are prefixed when
    # a "_" character to avoid possible conflict with XML tag names.

    # Insert text directly in to the builder's target.
    def _text(text)
      @target << text
    end

    # Insert special instruction.
    def _special(open, close, data=nil, attrs=nil, order=[])
      _indent
      @target << open
      @target << data if data
      _insert_attributes(attrs, order) if attrs
      @target << close
      _newline
    end

    # Start an XML tag.  If <tt>end_too</tt> is true, then the start
    # tag is also the end tag (e.g.  <br/>
    def _start_tag(sym, attrs, end_too=false)
      @target << "<#{sym}"
      _insert_attributes(attrs)
      @target << "/" if end_too
      @target << ">"
    end

    # Insert an ending tag.
    def _end_tag(sym)
      @target << "</#{sym}>"
    end

    # Insert the attributes (given in the hash).
    def _insert_attributes(attrs, order=[])
        #log!(:ins_attr, attrs)
      return if attrs.nil?
      order.each do |k|
        v = attrs[k]
        #log!(:seta, k, v)
        @target << %{ #{k}=#{@quote}#{_attr_value(v)}#{@quote}} if v
      end
      attrs.each do |k, v|
        #log!(:setb, k, v)
        @target << %{ #{k}=#{@quote}#{_attr_value(v)}#{@quote}} unless order.member?(k) # " WART
        #log!(:setb_targ, @target, _attr_value(v))
      end
    end

    def _attr_value(value)
      case value
      when ::Symbol
        value.to_s
      else
      #log!(:in_attr_v, value)
        outattr = _escape_attribute(value.to_s)
        #log!(:out_attr_v, outattr)
        outattr
      end
    end

    def _ensure_no_block(got_block)
      if got_block
        ::Kernel::raise IllegalBlockError.new(
          "Blocks are not allowed on XML instructions"
        )
      end
    end

  end

end



# = About lib/markaby.rb
#
# Markaby is a module containing all of the great Markaby classes that
# do such an excellent job.
#
# * Markaby::Builder: the class for actually calling the Ruby methods
#   which write the HTML.
# * Markaby::CSSProxy: a class which adds element classes and IDs to
#   elements when used within Markaby::Builder.
# * Markaby::MetAid: metaprogramming helper methods.
# * Markaby::Tags: lists the roles of various XHTML tags to help Builder
#   use these tags as they are intended.
module Markaby
  MAJOR = 0
  MINOR = 9
  TINY = 0

  VERSION = "#{MAJOR}.#{MINOR}.#{TINY}"

  class InvalidXhtmlError < StandardError; end

#require 'builder' unless defined?(Builder)
#require 'markaby/builder'
#require 'markaby/cssproxy'
#require 'markaby/tags'
#require 'markaby/builder_tags'

  RUBY_VERSION_ID = RUBY_VERSION.split(".").join.to_i

  FORM_TAGS         = [ :form, :input, :select, :textarea ]
  SELF_CLOSING_TAGS = [:area, :base, :br, :col, :command, :embed, :frame, :hr,
                       :img, :input, :keygen, :link, :meta, :param, :source,
                       :track, :wbr]

  # Common sets of attributes.
  AttrCore   = [:id, :class, :style, :title]
  AttrI18n   = [:lang, 'xml:lang'.intern, :dir]
  AttrEvents = [:onclick,
                :ondblclick,
                :onmousedown,
                :onmouseup,
                :onmouseover,
                :onmousemove,
                :onmouseout,
                :onkeypress,
                :onkeydown,
                :onkeyup]
  AttrFocus  = [:accesskey, :tabindex, :onfocus, :onblur]
  AttrHAlign = [:align, :char, :charoff]
  AttrVAlign = [:valign]
  Attrs      = AttrCore + AttrI18n + AttrEvents

  AttrsBoolean = [
    :checked, :disabled, :multiple, :readonly, :selected, # standard forms
    :autofocus, :required, :novalidate, :formnovalidate, # HTML5 forms
    :defer, :ismap, # <script defer>, <img ismap>
    :compact, :declare, :noresize, :noshade, :nowrap # deprecated or unused
  ]


  class Tagset
    class << self
      attr_accessor :tags, :tagset, :forms, :self_closing, :doctype

      def default_options
        {
          :tagset => self
        }
      end
    end
  end

  class XmlTagset < Tagset
    class << self
      def default_options
        super.merge({
          :output_xml_instruction => true,
          :output_meta_tag        => 'xhtml',
          :root_attributes        => {
            :xmlns      => 'http://www.w3.org/1999/xhtml',
            :'xml:lang' => 'en',
            :lang       => 'en'
          }
        })
      end
    end
  end

  # All the tags and attributes from XHTML 1.0 Strict
  class XHTMLStrict < XmlTagset
    @doctype = ['-//W3C//DTD XHTML 1.0 Strict//EN', 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd']
    @tagset  = {
      :html       => AttrI18n + [:id, :xmlns],
      :head       => AttrI18n + [:id, :profile],
      :title      => AttrI18n + [:id],
      :base       => [:href, :id],
      :meta       => AttrI18n + [:id, :http, :name, :content, :scheme, 'http-equiv'.intern],
      :link       => Attrs    + [:charset, :href, :hreflang, :type, :rel, :rev, :media],
      :style      => AttrI18n + [:id, :type, :media, :title, 'xml:space'.intern],
      :script     => [:id, :charset, :type, :src, :defer, 'xml:space'.intern],
      :noscript   => Attrs,
      :body       => Attrs + [:onload, :onunload],
      :div        => Attrs,
      :p          => Attrs,
      :ul         => Attrs,
      :ol         => Attrs,
      :li         => Attrs,
      :dl         => Attrs,
      :dt         => Attrs,
      :dd         => Attrs,
      :address    => Attrs,
      :hr         => Attrs,
      :pre        => Attrs + ['xml:space'.intern],
      :blockquote => Attrs + [:cite],
      :ins        => Attrs + [:cite, :datetime],
      :del        => Attrs + [:cite, :datetime],
      :a          => Attrs + AttrFocus + [:charset, :type, :name, :href, :hreflang, :rel, :rev, :shape, :coords],
      :span       => Attrs,
      :bdo        => AttrCore + AttrEvents + [:lang, 'xml:lang'.intern, :dir],
      :br         => AttrCore,
      :em         => Attrs,
      :strong     => Attrs,
      :dfn        => Attrs,
      :code       => Attrs,
      :samp       => Attrs,
      :kbd        => Attrs,
      :var        => Attrs,
      :cite       => Attrs,
      :abbr       => Attrs,
      :acronym    => Attrs,
      :q          => Attrs + [:cite],
      :sub        => Attrs,
      :sup        => Attrs,
      :tt         => Attrs,
      :i          => Attrs,
      :b          => Attrs,
      :big        => Attrs,
      :small      => Attrs,
      :object     => Attrs + [:declare, :classid, :codebase, :data, :type, :codetype, :archive, :standby, :height, :width, :usemap, :name, :tabindex],
      :param      => [:id, :name, :value, :valuetype, :type],
      :img        => Attrs + [:src, :alt, :longdesc, :height, :width, :usemap, :ismap],
      :map        => AttrI18n + AttrEvents + [:id, :class, :style, :title, :name],
      :area       => Attrs + AttrFocus + [:shape, :coords, :href, :nohref, :alt],
      :form       => Attrs + [:action, :method, :enctype, :onsubmit, :onreset, :accept, :accept],
      :label      => Attrs + [:for, :accesskey, :onfocus, :onblur],
      :input      => Attrs + AttrFocus + [:type, :name, :value, :checked, :disabled, :readonly, :size, :maxlength, :src, :alt, :usemap, :onselect, :onchange, :accept],
      :select     => Attrs + [:name, :size, :multiple, :disabled, :tabindex, :onfocus, :onblur, :onchange],
      :optgroup   => Attrs + [:disabled, :label],
      :option     => Attrs + [:selected, :disabled, :label, :value],
      :textarea   => Attrs + AttrFocus + [:name, :rows, :cols, :disabled, :readonly, :onselect, :onchange],
      :fieldset   => Attrs,
      :legend     => Attrs + [:accesskey],
      :button     => Attrs + AttrFocus + [:name, :value, :type, :disabled],
      :table      => Attrs + [:summary, :width, :border, :frame, :rules, :cellspacing, :cellpadding],
      :caption    => Attrs,
      :colgroup   => Attrs + AttrHAlign + AttrVAlign + [:span, :width],
      :col        => Attrs + AttrHAlign + AttrVAlign + [:span, :width],
      :thead      => Attrs + AttrHAlign + AttrVAlign,
      :tfoot      => Attrs + AttrHAlign + AttrVAlign,
      :tbody      => Attrs + AttrHAlign + AttrVAlign,
      :tr         => Attrs + AttrHAlign + AttrVAlign,
      :th         => Attrs + AttrHAlign + AttrVAlign + [:abbr, :axis, :headers, :scope, :rowspan, :colspan],
      :td         => Attrs + AttrHAlign + AttrVAlign + [:abbr, :axis, :headers, :scope, :rowspan, :colspan],
      :h1         => Attrs,
      :h2         => Attrs,
      :h3         => Attrs,
      :h4         => Attrs,
      :h5         => Attrs,
      :h6         => Attrs
    }

    @tags         = @tagset.keys
    @forms        = @tags & FORM_TAGS
    @self_closing = @tags & SELF_CLOSING_TAGS
  end

  # Additional tags found in XHTML 1.0 Transitional
  class XHTMLTransitional < XmlTagset
    @doctype = ['-//W3C//DTD XHTML 1.0 Transitional//EN', 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd']
    @tagset = XHTMLStrict.tagset.merge({
      :strike   => Attrs,
      :center   => Attrs,
      :dir      => Attrs + [:compact],
      :noframes => Attrs,
      :basefont => [:id, :size, :color, :face],
      :u        => Attrs,
      :menu     => Attrs + [:compact],
      :iframe   => AttrCore + [:longdesc, :name, :src, :frameborder, :marginwidth, :marginheight, :scrolling, :align, :height, :width],
      :font     => AttrCore + AttrI18n + [:size, :color, :face],
      :s        => Attrs,
      :applet   => AttrCore + [:codebase, :archive, :code, :object, :alt, :name, :width, :height, :align, :hspace, :vspace],
      :isindex  => AttrCore + AttrI18n + [:prompt]
    })

    # Additional attributes found in XHTML 1.0 Transitional
    additional_tags = {
      :script => [:language],
      :a      => [:target],
      :td     => [:bgcolor, :nowrap, :width, :height],
      :p      => [:align],
      :h5     => [:align],
      :h3     => [:align],
      :li     => [:type, :value],
      :div    => [:align],
      :pre    => [:width],
      :body   => [:background, :bgcolor, :text, :link, :vlink, :alink],
      :ol     => [:type, :compact, :start],
      :h4     => [:align],
      :h2     => [:align],
      :object => [:align, :border, :hspace, :vspace],
      :img    => [:name, :align, :border, :hspace, :vspace],
      :link   => [:target],
      :legend => [:align],
      :dl     => [:compact],
      :input  => [:align],
      :h6     => [:align],
      :hr     => [:align, :noshade, :size, :width],
      :base   => [:target],
      :ul     => [:type, :compact],
      :br     => [:clear],
      :form   => [:name, :target],
      :area   => [:target],
      :h1     => [:align]
    }

    additional_tags.each do |k, v|
      @tagset[k] += v
    end

    @tags = @tagset.keys
    @forms = @tags & FORM_TAGS
    @self_closing = @tags & SELF_CLOSING_TAGS
  end

  # Additional tags found in XHTML 1.0 Frameset
  class XHTMLFrameset < XmlTagset
    @doctype = ['-//W3C//DTD XHTML 1.0 Frameset//EN', 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd']
    @tagset = XHTMLTransitional.tagset.merge({
      :frameset => AttrCore + [:rows, :cols, :onload, :onunload],
      :frame    => AttrCore + [:longdesc, :name, :src, :frameborder, :marginwidth, :marginheight, :noresize, :scrolling]
    })

    @tags = @tagset.keys
    @forms = @tags & FORM_TAGS
    @self_closing = @tags & SELF_CLOSING_TAGS
  end


  class HTML5 < Tagset
    class << self
      def default_options
        super.merge({
          :output_xml_instruction => false,
          :output_meta_tag        => 'html5',
          :root_attributes        => {}
        })
      end
    end

    @doctype = ['html']
    @tagset = XHTMLTransitional.tagset.merge({
      :abbr => Attrs,
      :article => Attrs,
      :aside => Attrs,
      :audio => Attrs,
      :bdi => Attrs,
      :canvas => Attrs,
      :command => Attrs,
      :datalist => Attrs,
      :details => Attrs,
      :embed => Attrs,
      :figure => Attrs,
      :figcaption => Attrs,
      :footer => Attrs,
      :header => Attrs,
      :hgroup => Attrs,
      :keygen => Attrs,
      :mark => Attrs,
      :menu => Attrs,
      :meter => Attrs,
      :nav => Attrs,
      :output => Attrs,
      :progress => Attrs,
      :rp => Attrs,
      :rt => Attrs,
      :ruby => Attrs,
      :section => Attrs,
      :source => Attrs,
      :time => Attrs,
      :track => Attrs,
      :video => Attrs,
      :wbr => Attrs
    })

    # Additional attributes found in HTML5
    additional_tags = {
      :a => [:media, :download, :ping],
      :area => [:media, :download, :ping, :hreflang, :rel, :type],
      :base => [:target],
      :button => [:autofocus, :form, :formaction, :formenctype, :formmethod,
                  :formnovalidate, :formtarget],
      :fieldset => [:form, :disabled, :name],
      :form => [:novalidate],
      :label => [:form],
      :html => [:manifest],
      :iframe => [:sandbox, :seamless, :srcdoc],
      :img => [:crossorigin],
      :input => [:autofocus, :placeholder, :form, :required, :autocomplete,
                 :min, :max, :multiple, :pattern, :step, :list, :width, :height,
                 :dirname, :formaction, :formenctype, :formmethod,
                 :formnovalidate, :formtarget],
      :link => [:sizes],
      :meta => [:charset],
      :menu => [:type, :label],
      :object => [:form, :typemustmatch],
      :ol => [:reversed],
      :output => [:form],
      :script => [:async],
      :select => [:autofocus, :form, :required],
      :style => [:scoped],
      :textarea => [:autofocus, :placeholder, :form, :required, :dirname,
                    :maxlength, :wrap],
    }

    AttrsHTML5  = [:contenteditable, :contextmentu, :draggable, :dropzone,
                   :hidden, :role, :spellcheck, :translate]

    additional_tags.each do |k, v|
      @tagset[k] += v
    end

    @tagset.each do |k, v|
      @tagset[k] += AttrsHTML5
    end

    @tags = @tagset.keys
    @forms = @tags & FORM_TAGS
    @self_closing = @tags & SELF_CLOSING_TAGS
  end

  class Stream < Array
    alias_method :to_s, :join
  end

  module BuilderTags
    (HTML5.tags - [:head]).each do |k|
    #log!(:wtf234234, self, k.to_s)

      #, __FILE__, __LINE__
      #<<-CODE
      class_eval do
        define_method(k) do |*args, &block|
          html_tag(k.to_s, *args, &block)
        end
      end
      #CODE
    end

    # Every HTML tag method goes through an html_tag call.  So, calling <tt>div</tt> is equivalent
    # to calling <tt>html_tag(:div)</tt>.  All HTML tags in Markaby's list are given generated wrappers
    # for this method.
    #
    # If the @auto_validation setting is on, this method will check for many common mistakes which
    # could lead to invalid XHTML.
    def html_tag(sym, *args, &block)
      if @auto_validation && @tagset.self_closing.include?(sym) && block
        raise InvalidXhtmlError, "the `#{sym}' element is self-closing, please remove the block"
      elsif args.empty? && !block
        CssProxy.new(self, @streams.last, sym)
      else
        tag!(sym, *args, &block)
      end
    end

    # Builds a head tag.  Adds a <tt>meta</tt> tag inside with Content-Type
    # set to <tt>text/html; charset=utf-8</tt>.
    def head(*args, &block)
      tag!(:head, *args) do
        tag!(:meta, "http-equiv" => "Content-Type", "content" => "text/html; charset=utf-8") if @output_meta_tag == 'xhtml'
        if @output_meta_tag == 'html5'
          tag!(:meta, "charset" => "utf-8") 
        end
        instance_eval(&block)
      end
    end

    # Builds an html tag.  An XML 1.0 instruction and an XHTML 1.0 Transitional doctype
    # are prepended.  Also assumes <tt>:xmlns => "http://www.w3.org/1999/xhtml",
    # :lang => "en"</tt>.
    def xhtml_transitional(attrs = {}, &block)
      self.tagset = Markaby::XHTMLTransitional
      xhtml_html(attrs, &block)
    end

    # Builds an html tag with XHTML 1.0 Strict doctype instead.
    def xhtml_strict(attrs = {}, &block)
      self.tagset = Markaby::XHTMLStrict
      xhtml_html(attrs, &block)
    end

    # Builds an html tag with XHTML 1.0 Frameset doctype instead.
    def xhtml_frameset(attrs = {}, &block)
      self.tagset = Markaby::XHTMLFrameset
      xhtml_html(attrs, &block)
    end

    # Builds an html tag with HTML5 doctype instead.
    def html5(attrs = {}, &block)
      self.tagset = Markaby::HTML5
      html5_html(attrs, &block)
    end

    def enable_html5!
      raise NotImplementedError, "Deprecated! Call self.tagset = Markaby::HTML5"
    end

  private

    def xhtml_html(attrs = {}, &block)
      instruct! if @output_xml_instruction
      declare!(:DOCTYPE, :html, :PUBLIC, *tagset.doctype)
      tag!(:html, @root_attributes.merge(attrs), &block)
    end

    def html5_html(attrs = {}, &block)
      declare!(:DOCTYPE, :html)
      tag!(:html, @root_attributes.merge(attrs), &block)
    end
  end



  # The Markaby::Builder class is the central gear in the system.  When using
  # from Ruby code, this is the only class you need to instantiate directly.
  #
  #   mab = Markaby::Builder.new
  #   mab.html do
  #     head { title "Boats.com" }
  #     body do
  #       h1 "Boats.com has great deals"
  #       ul do
  #         li "$49 for a canoe"
  #         li "$39 for a raft"
  #         li "$29 for a huge boot that floats and can fit 5 people"
  #       end
  #     end
  #   end
  #   puts mab.to_s
  #
  class Builder
    include Markaby::BuilderTags

    GENERIC_OPTIONS = {
      :indent                 => 0,
      :auto_validation        => true,
    }

    HTML5_OPTIONS   = HTML5.default_options.dup
    DEFAULT_OPTIONS = GENERIC_OPTIONS.merge(HTML5_OPTIONS)

    @@options = DEFAULT_OPTIONS.dup

    def self.restore_defaults!
      @@options = DEFAULT_OPTIONS.dup
    end

    def self.set(option, value)
      @@options[option] = value
    end

    def self.get(option)
      @@options[option]
    end

    attr_reader :tagset

    def tagset=(tagset)
      @tagset = tagset

      tagset.default_options.each do |k, v|
        self.instance_variable_set("@#{k}".to_sym, v)
      end
    end

    # Create a Markaby builder object.  Pass in a hash of variable assignments to
    # +assigns+ which will be available as instance variables inside tag construction
    # blocks.  If an object is passed in to +helper+, its methods will be available
    # from those same blocks.
    #
    # Pass in a +block+ to new and the block will be evaluated.
    #
    #   mab = Markaby::Builder.new {
    #     html do
    #       body do
    #         h1 "Matching Mole"
    #       end
    #     end
    #   }
    #
    def initialize(assigns = {}, helper = nil, &block)
      @streams = [Stream.new]
      @assigns = assigns.dup
      @_helper = helper
      @used_ids = {}

      @@options.each do |k, v|
        instance_variable_set("@#{k}", @assigns.delete(k) || v)
      end

      @assigns.each do |k, v|
        instance_variable_set("@#{k}", v)
      end

      if helper
        helper.instance_variables.each do |iv|
          instance_variable_set(iv, helper.instance_variable_get(iv))
        end
      end

      @builder = XmlMarkup.new(:indent => @indent, :target => @streams.last)

      text(capture(&block)) if block
    end

    def helper=(helper)
      @_helper = helper
    end

    def metaclass(&block)
      metaclass = class << self; self; end
      metaclass.class_eval(&block)
    end

    private :metaclass

    def locals=(locals)
      locals.each do |key, value|
        metaclass do
          define_method key do
            value
          end
        end
      end
    end

    # Returns a string containing the HTML stream.  Internally, the stream is stored as an Array.
    def to_s
      @streams.last.to_s
    end

    # Write a +string+ to the HTML stream without escaping it.
    def text(string)
      @builder << string.to_s
      nil
    end
    alias_method :<<, :text
    alias_method :concat, :text

    # Captures the HTML code built inside the +block+.  This is done by creating a new
    # stream for the builder object, running the block and passing back its stream as a string.
    #
    #   >> Markaby::Builder.new.capture { h1 "TEST"; h2 "CAPTURE ME" }
    #   => "<h1>TEST</h1><h2>CAPTURE ME</h2>"
    #
    def capture(&block)
      @streams.push(@builder.target = Stream.new)
      @builder.level += 1
      str = instance_eval(&block)
      str = @streams.last.join if @streams.last.any?
      @streams.pop
      @builder.level -= 1
      @builder.target = @streams.last
      str
    end

    # Create a tag named +tag+. Other than the first argument which is the tag name,
    # the arguments are the same as the tags implemented via method_missing.
    def tag!(tag, *args, &block)
      ele_id = nil

#log!("WTF", args)

      # TODO: Move this logic to the tagset so that the tagset itself can validate + raise when invalid
      if @auto_validation && @tagset
        if !@tagset.tagset.has_key?(tag.to_sym)
        #log!(@tagset.tagset.keys, tag)
          raise InvalidXhtmlError, "#{@tagset} #{tagset} no element `#{tag}' for #{tagset.doctype}"
        elsif args.last.respond_to?(:to_hash) || args.last.class == Hash
          attrs = args.last#.to_hash

          if @tagset.forms.include?(tag) && attrs[:id]
            attrs[:name] ||= attrs[:id]
          end

          attrs.each do |k, v|
            atname = k.to_s.downcase.intern
            #raise "wtf #{atname} #{AttrsBoolean}"

            #TODO
            #unless k =~ /:/ or @tagset.tagset[tag].include?(atname) or (@tagset == Markaby::HTML5 && atname.to_s =~ /^data-/)
            #  raise InvalidXhtmlError, "no attribute `#{k}' on #{tag} elements"
            #end

            if atname == :id
              ele_id = v.to_s

              if @used_ids.has_key? ele_id
                raise InvalidXhtmlError, "id `#{ele_id}' already used (id's must be unique)."
              end
            end

            if AttrsBoolean.include? atname
              if v
                attrs[k] = atname.to_s
              else
                attrs.delete k
              end
            end
          end
        end
      end

      if block
        str = capture(&block)
        block = Proc.new { text(str) }
      end

      f = fragment { @builder.tag!(tag, *args, &block) }
      @used_ids[ele_id] = f if ele_id
      f
    end

  private

    # This method is used to intercept calls to helper methods and instance
    # variables.  Here is the order of interception:
    #
    # * If +sym+ is a helper method, the helper method is called
    #   and output to the stream.
    # * If +sym+ is a Builder::XmlMarkup method, it is passed on to the builder object.
    # * If +sym+ is also the name of an instance variable, the
    #   value of the instance variable is returned.
    # * If +sym+ has come this far and no +tagset+ is found, +sym+ and its arguments are passed to tag!
    # * If a tagset is found, though, +NoMethodError+ is raised.
    #
    # method_missing used to be the lynchpin in Markaby, but it's no longer used to handle
    # HTML tags.  See html_tag for that.
    def method_missing(sym, *args, &block)
      if @_helper.respond_to?(sym, true)
        @_helper.send(sym, *args, &block)
      elsif @assigns.has_key?(sym)
        @assigns[sym]
      elsif @assigns.has_key?(stringy_key = sym.to_s)
        # Rails' ActionView assigns hash has string keys for
        # instance variables that are defined in the controller.
        @assigns[stringy_key]
      elsif instance_variables_for(self).include?(ivar = "@#{sym}".to_sym)
        instance_variable_get(ivar)
      elsif @_helper && instance_variables_for(@_helper).include?(ivar)
        @_helper.instance_variable_get(ivar)
      elsif instance_methods_for(::Builder::XmlMarkup).include?(sym)
        @builder.__send__(sym, *args, &block)
      elsif !@tagset
        tag!(sym, *args, &block)
      else
#log!(instance_methods_for(::Builder::XmlMarkup))
#log!(instance_methods_for(::Builder::XmlMarkup))
      #log!(:mmissing, sym, args)
        super
      end
    end

    if RUBY_VERSION_ID >= 191
      def instance_variables_for(obj)
        obj.instance_variables
      end

      def instance_methods_for(obj)
        obj.instance_methods
      end
    else
      def instance_variables_for(obj)
        obj.instance_variables.map { |var| var.to_sym }
      end

      def instance_methods_for(obj)
        obj.instance_methods.map { |m| m.to_sym }
      end
    end

    def fragment
      stream = @streams.last
      start = stream.length
      yield
      length = stream.length - start
      Fragment.new(stream, start, length)
    end
  end


  # Class used by Markaby::Builder to store element options.  Methods called
  # against the CssProxy object are added as element classes or IDs.
  #
  # See the README for examples.
  class CssProxy
    def initialize(builder, stream, sym)
      @builder = builder
      @stream  = stream
      @sym     = sym
      @attrs   = {}

      @original_stream_length = @stream.length

      @builder.tag! sym
    end

    def respond_to?(sym, include_private = false)
      include_private || !private_methods.map { |m| m.to_sym }.include?(sym.to_sym) ? true : false
    end

  private

    # Adds attributes to an element.  Bang methods set the :id attribute.
    # Other methods add to the :class attribute.
    def method_missing(id_or_class, *args, &block)
      #TODO:
      #if id_or_class.to_s =~ /(.*)!$/
      #  @attrs[:id] = $1
      #else
      #  id = id_or_class
      #  @attrs[:class] = @attrs[:class] ? "#{@attrs[:class]} #{id}".strip : id
      #end

      unless args.empty?
        if args.last.respond_to? :to_hash
          @attrs.merge! args.pop.to_hash
        end
      end

      args.push(@attrs)

      while @stream.length > @original_stream_length
        @stream.pop
      end

      if block
        @builder.tag! @sym, *args, &block
      else
        @builder.tag! @sym, *args
      end

      self
    end
  end

  # Every tag method in Markaby returns a Fragment.  If any method gets called on the Fragment,
  # the tag is removed from the Markaby stream and given back as a string.  Usually the fragment
  # is never used, though, and the stream stays intact.
  #
  # For a more practical explanation, check out the README.
  class Fragment #< ::Builder::BlankSlate
    def initialize(*args)
      @stream, @start, @length = args
      @transformed_stream = false
    end

    [:to_s, :inspect, :==].each do |method|
      undef_method method if method_defined?(method)
    end

  private

    def method_missing(*args, &block)
      transform_stream unless transformed_stream?
      @str.__send__(*args, &block)
    end

    def transform_stream
      @transformed_stream = true

      # We can't do @stream.slice!(@start, @length),
      # as it would invalidate the @starts and @lengths of other Fragment instances.
      @str = @stream[@start, @length].to_s
      @stream[@start, @length] = [nil] * @length
    end

    def transformed_stream?
      @transformed_stream
    end
  end

  class XmlMarkup < ::Builder::XmlMarkup
    attr_accessor :target, :level
  end

#module Kernel
#  # Shortcut for creating a quick block of Markaby.
#  def mab(*args, &block)
#    Markaby::Builder.new(*args, &block).to_s
#  end
#end
#require 'markaby'

  module Rails
    class TemplateHandler
      class << self
        def register!(options={})
          self.options = options
          ActionView::Template.register_template_handler(:mab, new)
        end

        # TODO: Do we need this?
        # Default format used by Markaby
        # class_attribute :default_format
        # self.default_format = :html

        def options
          @options ||= {}
        end

        def options=(val)
          self.options.merge!(val)
          self.options
        end
      end

      def call(template)
        <<-CODE
          Markaby::Builder.new(Markaby::Rails::TemplateHandler.options, self) do
            #{template.source}
          end.to_s
        CODE
      end
    end
  end
end
