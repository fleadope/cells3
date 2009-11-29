module Cell
  module Rendering
    extend ActiveSupport::Concern

    include AbstractController::RenderingController
    included do
      # We should use respond_to instead of that
      class_inheritable_accessor :default_template_format
      self.default_template_format = :html
    end

    module InstanceMethods

      # Render the given state.  You can pass the name as either a symbol or
      # a string.
      def render_state(state)
        ### DISCUSS: are these vars really needed in state views?
        @cell       = self
        @state_name = state
        
        output = process(state)
        if output.is_a?(String)
          self.response_body = output
        elsif output.nil?
          self.response_body = render
        else
          raise CellError.new( "#{cell_name}/#{state} must call explicit render" )
        end
      end

      # Render the view for the current state. Usually called at the end of a state method.
      #
      # ==== Cells-specific Options
      # * <tt>:view</tt> - Specifies the name of the view file to render. Defaults to the current state name.
      # * <tt>:template_format</tt> - Allows using a format different to <tt>:html</tt>.
      # * <tt>:layout</tt> - If set to a valid filename inside your cell's view_paths, the current state view will be rendered inside the layout (as known from controller actions). Layouts should reside in <tt>app/cells/layouts</tt>.
      #
      # Example:
      #  class MyCell < Cell::Base
      #    def my_first_state
      #      # ... do something
      #      render 
      #    end
      #
      # will just render the view <tt>my_first_state.html</tt>.
      # 
      #    def my_first_state
      #      # ... do something
      #      render :view => :my_first_state, :layout => "metal"
      #    end
      #
      # will also use the view <tt>my_first_state.html.erb</tt> as template and even put it in the layout
      # <tt>metal</tt> that's located at <tt>$RAILS_ROOT/app/cells/layouts/metal.html.erb</tt>.
      #
      # === Render options
      # You can use usual render options as weel
      #
      # Example:
      #   render :action => 'foo'
      #   render :text => 'Hello Cells'
      #   render :inline => 'Welcome'
      #   render :file => 'another_cell/foo'
      #
      # But you're not obligated to use render at all.
      #
      # class BarCell < Cell::Base
      # 
      #   def bar_state
      #   end
      #
      # end
      # 
      # <tt>bar_state.html.erb</tt> will be rendered.
      #
      def render(options = {})
        normalize_render_options(options)
        render_to_body(options)
      end

      # Normalize the passed options from #render.
      def normalize_render_options(opts)
        opts[:formats] ||= [opts.delete(:template_format) || self.class.default_template_format]
        if (opts.keys & [:file, :text, :inline, :nothing, :partial, :template]).empty?
          opts[:template] ||= opts.delete(:view) || opts.delete(:state) || state_name
          opts[:_prefix] = find_template_path(opts[:template], :formats => opts[:formats])
        end
        opts
      end

      # overridden to use Cell::View instead of ActionView::Base
      def view_context
        @_view_context ||= Cell::View.for_controller(self)
      end

      # Climbs up the inheritance hierarchy of the Cell, looking for a view 
      # for the current <tt>state</tt> in each level.
      def find_template_path(state, options)
        returning possible_view_paths.detect { |path| view_paths.exists?( state.to_s, options, path ) } do |path|
          raise ::ActionView::MissingTemplate.new(view_paths, state.to_s) unless path
        end
      end

      # Find possible files that belong to the state.  This first tries the cell's
      # <tt>#view_for_state</tt> method and if that returns a true value, it
      # will accept that value as a string and interpret it as a pathname for
      # the view file. If it returns a falsy value, it will call the Cell's class
      # method find_class_view_for_state to determine the file to check.
      #
      # You can override the Cell::Base#view_for_state method for a particular
      # cell if you wish to make it decide dynamically what file to render.
      def possible_view_paths
        ::Cell::Base.inheritance_path
      end

      # Defines the instance variables that should <em>not</em> be copied to the 
      # View instance.
      def protected_instance_variables  
        ['@parent_controller'] 
      end

    end

  end
end
