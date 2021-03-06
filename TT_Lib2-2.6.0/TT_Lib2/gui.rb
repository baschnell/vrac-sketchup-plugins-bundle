#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'TT_Lib2/core.rb'

# Wrapper library for creating and manipulating WebDialogs and HTML content
# via Ruby.
#
# @deprecated Alpha stage. Very likely to be subject to change!
module TT::GUI

  # http://juixe.com/techknow/index.php/2007/01/22/ruby-class-tutorial/
  # http://stackoverflow.com/questions/1645398/ruby-include-question
  
  # http://railstips.org/blog/archives/2006/11/18/class-and-instance-variables-in-ruby/
  #
  # @since 2.6.0
  module ControlEvents

    # @since 2.6.0
    def self.included( base )
      # Hash table of valid events for the class.
      # > Key: (Symbol)
      # > Value: (Symbol)
      base.instance_variable_set( '@control_events', {} )
      base.extend( ControlEventDefinitions )
    end
    
    # @since 2.6.0
    module ControlEventDefinitions
      
      # @since 2.6.0
      def inherited( subclass )
        instance_var = '@control_events'
        parent_events = instance_variable_get( instance_var ).dup
        subclass.instance_variable_set( instance_var, parent_events )
      end
      
    end # module ControlEventDefinitions

  end # module ControlEvents
	
  
  # All GUI elements inherit this class.
  #
	# @abstract
	# @since 2.4.0
	class Control
    include ControlEvents
    
		attr_accessor( :ui_id ) # @since 2.4.0
		attr_accessor( :left, :right, :top, :bottom, :height, :width ) # @since 2.4.0
		attr_accessor( :parent, :window ) # @since 2.4.0
		attr_accessor( :tooltip ) # @since 2.5.0
    
    # (!) Tab Index
    
    # Base Events:
    # * click, double-click (?)
    # * keydown, keypress, keyup (?)
    # * mousein, mouseout, mousemove
    # * mousebuttondown, mousebuttonup
    # * focus, blur
		
		# @since 2.4.0
		def initialize( *args )
      # Unique identifier used in the WebDialog's HTML.
			@ui_id = 'UI_' + self.object_id.to_s
      # Hash with Symbols for keys idenitfying the event.
      # Each event is an array of Proc's.
      @events = {}
		end
    
    
    # @return [Array<Symbol>]
		# @since 2.6.0
    def self.events
      @control_events.keys
    end
    
    # @return [Array<Symbol>]
		# @since 2.6.0
    def self.has_event?( event )
      @control_events.key?( event )
    end
    
    
    # Adds an event to the stack.
    #
    # @param [Symbol] event
    # @param [Proc] proc
    #
    # @return [nil]
		# @since 2.5.0
    def add_event_handler( event, &block )
      unless self.class.has_event?( event )
        raise( ArgumentError, "Event #{event} not defined for #{self.class}" )
      end
      @events[event] ||= []
      @events[event] << block
      nil
    end
    
    # Triggers the given event. All attached procs for that event will be called.
    #
    # @param [Symbol] event
    # @param [Array] args Set of arguments to be passed to the called procs.
    #
    # @return [Boolean]
		# @since 2.5.0
    def call_event( event, args = nil )
      TT::debug "call_event(#{event.to_s})"
      TT::debug args.inspect
      if @events.key?( event )
        @events[event].each { |proc|
          next if proc.nil? # In case Button control where made without a block.
          # Add self to argument list so the called event can get the handle for
          # the control triggering it.
          if args.nil?
            proc.call( self )
          else
            args.unshift( self )
            proc.call( *args )
          end
        }
        true
      else
        # (?) Raise error?
        false
      end
    end
		
    # @param [Numeric] value
    #
    # @return [Numeric]
    # @since 2.6.0
		def top=( value )
			@top = value
      update_html_element( { :top => value } )
      value
		end
    
    # @param [Numeric] value
    #
    # @return [Numeric]
    # @since 2.6.0
		def left=( value )
			@left = value
      update_html_element( { :left => value } )
      value
		end
    
    # @param [Numeric] value
    #
    # @return [Numeric]
    # @param [Numeric] value
    #
    # @return [Numeric]
    # @since 2.6.0
		def bottom=( value )
			@bottom = value
      update_html_element( { :bottom => value } )
      value
		end
    
    # @param [Numeric] value
    #
    # @return [Numeric]
    # @since 2.6.0
		def right=( value )
			@right = value
      update_html_element( { :right => value } )
      value
		end
    
    # @param [Numeric] value
    #
    # @return [Numeric]
    # @since 2.6.0
		def width=( value )
			@width = value
      update_html_element( { :width => value } )
      value
		end
    
    # @param [Numeric] value
    #
    # @return [Numeric]
    # @since 2.6.0
		def height=( value )
			@height = value
      update_html_element( { :height => value } )
      value
		end
    
    # @param [Numeric] left
    # @param [Numeric] top
    #
    # @return [Array<Numeric,Numeric>]
		# @since 2.4.0
		def move( left, top )
			@left = left
			@top  = top
      update_html_element( { :left => left, :top => top } )
      [ left, top ]
		end
		
    # @param [Numeric] width
    # @param [Numeric] height
    #
    # @return [Array<Numeric,Numeric>]
		# @since 2.4.0
		def size( width, height )
			@width  = width
			@height = height
      update_html_element( { :width => width, :height => height } )
      [ width, height ]
		end
		
    # @param [Numeric] top
    # @param [Numeric] right
    # @param [Numeric] bottom
    # @param [Numeric] left
    #
    # @return [Array<Numeric,Numeric,Numeric,Numeric>]
		# @since 2.4.0
		def position( top, right, bottom, left )
			@top	= top
			@right	= right
			@bottom	= bottom
			@left	= left
      properties = {
        :top => top,
        :right => right,
        :bottom => bottom,
        :left => left
      }
      update_html_element( properties )
      [ top, right, bottom, left ]
		end
    
    # (!) Need explicit :position property.
		# @return [Boolean]
		# @since 2.5.0
    def positioned?
      ( @left || @right || @top || @bottom ) ? true : false
    end
    
    # @return [TT::JSON]
		# @since 2.5.0
    def properties
      options = TT::JSON.new
      options['id'] = @ui_id
      options['parent'] = @parent.ui_id if @parent.is_a?( Control )
      options['type'] = self.class.name
      if positioned?
        options['top']    = @top    if @top
        options['bottom'] = @bottom if @bottom
        options['left']   = @left   if @left
        options['right']  = @right  if @right
      end
      options['width']    = @width  if @width
      options['height']   = @height if @height
      if self.respond_to?( :custom_properties )
        options.merge!( custom_properties() )
      end
      options
    end
    
    # @return [String]
    # @since 2.6.0
    def inspect
      "<#{self.class}:#{TT.object_id_hex(self)}>"
    end
    
    # Release all references to other objects. Setting them to nil. So that
    # the GC can collect them.
    #
    # @return [Nil]
    # @since 2.6.0
    def release!
      @parent = nil
      @window = nil
      @events.clear
      nil
    end
    
    private
    
    # @param [Hash] properties
    #
    # @return [Boolean]
    # @since 2.6.0
    def update_html_element( properties )
      if self.window && self.window.visible?
        self.window.call_script( 'UI.update_properties', self.ui_id, properties )
      else
        false
      end
    end
    
    # Defines an event for the control. If an event is not defines it cannot be
    # called.
    #
    # @param [Symbol] event
    #
    # @return [Nil]
		# @since 2.6.0
    def self.define_event( *args )
      for event in args
        raise( ArgumentError, 'Expected a Symbol' ) unless event.is_a?( Symbol )
        @control_events[event] = event
      end
      nil
    end
    
	end # class Control

	
	# @abstract +Container+ and +Window+ implements this.
	# @since 2.4.0
	module ContainerElement
  
		# @since 2.4.0
		attr( :controls )
		
		# @since 2.4.0
		def initialize( *args )
			super( *args )
			@controls = []
		end
		
    # @param [Control] control
    #
    # @return [Boolean] +True+ if the webdialog was open and the control added.
		# @since 2.4.0
		def add_control( control )
			raise( ArgumentError, 'Expected Control' ) unless control.is_a?( Control )
      # Add to Ruby DOM tree
			@controls << control
			control.parent = self
			control.window = self.window
      # Add to Webdialog
      if self.window && self.window.visible?
        self.window.add_control_to_webdialog( control )
        return true
      end
      false
		end
    
    # (!) remove_control
    
    # While #add_control add the control to the Ruby class's internal list, this
    # method adds the control to the webdialog.
    #
    # @private
    # @return [Nil]
    # @since 2.5.0
    def add_controls_to_webdialog
      for control in @controls
        @window.add_control_to_webdialog( control )
        if control.is_a?( ContainerElement )
          control.add_controls_to_webdialog
        end
      end
      nil
    end
    
    # @param [String] ui_id
    #
    # @return [Control,Nil]
    # @since 2.5.0
    def get_control_by_ui_id( ui_id )
      for control in @controls
				return control if control.ui_id == ui_id
        if control.is_a?( ContainerElement )
          result = control.get_control_by_ui_id( ui_id )
          return result if result
        end
			end
      nil
    end
    
    # @see Control#release!
    # @return [Nil]
    # @since 2.6.0
    def release!
      for control in @controls
        control.release!
      end
      @controls.clear
      super
    end
    
	end # module ContainerElement
	
	
	# @since 2.4.0
	class Container < Control
		include ContainerElement
	end # class Container
	
	
  # = Events
  # * +:click+
  #
	# @since 2.4.0
	class Button < Control
  
		# @since 2.4.0
		attr_accessor( :caption )
    
		# @since 2.6.0
    define_event( :click )
		
    # @param [String] caption
    # @param [Proc] on_click
    #
		# @since 2.4.0
		def initialize( caption, &on_click )
			super
      # Defaults
      # http://msdn.microsoft.com/en-us/library/aa511279.aspx#controlsizing
      # http://msdn.microsoft.com/en-us/library/aa511453.aspx#sizing
      # Actual: 75x23
      # Visible: 73x21
      @width = 73
      @height = 21
      # User Properties
			@caption = caption
      add_event_handler( :click, &on_click )
		end
    
    # @return [TT::JSON]
    # @since 2.5.0
    def custom_properties
      prop = TT::JSON.new
      prop['caption'] = @caption
      prop
    end
		
	end # class Button
  
  
  # @since 2.6.0
	class ToolbarButton < Button
  
		# @since 2.6.0
		attr_accessor( :icon )
		
    # @param [String] caption
    # @param [Proc] on_click
    #
		# @since 2.6.0
		def initialize( caption, &on_click )
			super
      # Defaults
      @width = 28
      @height = 28
		end
    
    # @return [TT::JSON]
    # @since 2.6.0
    def custom_properties
      # (!) Improve custom properties.
      prop = super
      #prop['caption'] = @caption
      prop['icon'] = @icon if @icon
      prop
    end
		
	end # class ToolbarButton
	
	
	# @since 2.4.0
	class Checkbox < Control
  
		# @since 2.4.0
		attr_accessor( :checked )
		
    # @param [String] label
    #
		# @since 2.4.0
		def initialize( label )
			super
			@label = label
		end
    
	end # class Checkbox
	
	
  # = Events
  # * +:change+
  #
	# @since 2.4.0
	class Listbox < Control
  
    # @since 2.5.0
		attr_reader( :value, :items, :size, :multiple )
    
    # @since 2.6.0
    define_event( :change )
		
    # @param [Array<String>] list
    #
		# @since 2.5.0
		def initialize( list = nil )
			super
			@value = nil
      @items = ( list.is_a?(Array) ) ? list : [] # (?) Hash instead?
      @size = nil
      @multiple = false
		end
    
    # @return [TT::JSON]
    # @since 2.5.0
    def custom_properties
      prop = TT::JSON.new
      prop['items'] = @items
      prop['size']  = @size if @size
      prop['multiple'] = @multiple if @multiple
      prop
    end
    
    # @param [String] string
    #
    # @return [String]
    # @since 2.5.0
    def add_item( string )
      @items << string
      string
    end
    
	end # class Listbox
	
	
  # = Events
  # * +:change+
  # * +:keydown+
  # * +:keypress+
  # * +:keyup+
  # * +:focus+
  # * +:blur+
  #
	# @since 2.4.0
	class Textbox < Control
  
		# @since 2.4.0
		attr_accessor( :value )
    
    # @since 2.6.0
    define_event( :change )
    define_event( :textchange )
    define_event( :keydown, :keypress, :keyup )
    define_event( :focus, :blur )
    define_event( :copy, :cut, :paste )
		
    # @param [String] value
    #
		# @since 2.4.0
		def initialize( value )
			super
			@value = value
		end
    
    # @return [String]
    # @since 2.6.0
		def value
			@value = self.window.get_element_value( self.ui_id )
		end
    
    # @param [String] string
    #
    # @return [String]
    # @since 2.6.0
		def value=( string )
			@value = string
      update_html_element( { :value => string } )
      string
		end
    
    # @return [TT::JSON]
    # @since 2.6.0
    def custom_properties
      prop = TT::JSON.new
      prop['value'] = @value
      prop
    end
    
	end # class Textbox
	
	
	# @since 2.4.0
	class Label < Control
  
		# @since 2.4.0
		attr_accessor( :caption )
		
    # @param [String] caption
    # @param [Control] control Control which receives focus when the Label is activated.
    #
		# @since 2.4.0
		def initialize( caption, control=nil )
			super
			@caption = caption
			@control = control
      # (!) Align
		end
    
    # @param [String] string
    #
    # @return [String]
    # @since 2.6.0
		def caption=( string )
			@caption = string
      update_html_element( { :caption => string } )
      string
		end
    
    # @return [TT::JSON]
    # @since 2.6.0
    def custom_properties
      prop = TT::JSON.new
      prop['caption'] = @caption
      prop['control'] = @control.ui_id if @control
      prop
    end
		
	end # class Label

end # module TT::GUI