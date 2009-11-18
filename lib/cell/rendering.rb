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
        content = process(state)
        return content if content.is_a?(String)

        ### DISCUSS: are these vars really needed in state views?
        @cell       = self
        @state_name = state

        output = self.response_body || render # Implicit render if #render havn't been called explicite
        # Allow render_state be called twice or more 
        # So we can render different state without recreating cell
        self.response_body = nil
        output
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
      def render(options = {}, *args)
        normalize_render_options(options)
        super(options, *args)
      end

      def template_path(view, options)
        # Have to add following slash as path must be absolute
        "/#{find_template_path(view, options)}"
      end

      # Normalize the passed options from #render.
      # TODO: that method is screwed up. Rewrite
      def normalize_render_options(opts)
        template_format = opts.delete(:template_format)
        view = opts.delete(:view) || opts.delete(:action)
        formats = [template_format || self.class.default_template_format]
        if view
          opts[:file] = template_path(view, :formats => formats)
        elsif opts.except(:layout).empty?
          opts[:file] = template_path(action_name, :formats => formats)
        end
        opts
      end

      # Climbs up the inheritance hierarchy of the Cell, looking for a view 
      # for the current <tt>state</tt> in each level.
      def find_template_path(state, options)
        returning possible_paths_for_state(state).detect { |path| view_paths.exists?( path, options ) } do |path|
          raise ::ActionView::MissingTemplate.new(view_paths, state.to_s) unless path
        end
      end

      # In production mode, the view for a state/template_extension is cached.
      ### DISCUSS: ActionView::Base already caches results for #pick_template, so maybe
      ### we should just cache the family path for a state/format?
      def find_family_view_for_state_with_caching(state, action_view)
        return find_family_view_for_state(state, action_view) unless self.class.cache_configured?

        # in production mode:
        key         = "#{state}/#{action_view.template_extension}"
        state2view  = self.class.state2view_cache
        state2view[key] || state2view[key] = find_family_view_for_state(state, action_view)
      end

      # Find possible files that belong to the state.  This first tries the cell's
      # <tt>#view_for_state</tt> method and if that returns a true value, it
      # will accept that value as a string and interpret it as a pathname for
      # the view file. If it returns a falsy value, it will call the Cell's class
      # method find_class_view_for_state to determine the file to check.
      #
      # You can override the Cell::Base#view_for_state method for a particular
      # cell if you wish to make it decide dynamically what file to render.
      def possible_paths_for_state(state)
        self.class.find_class_view_for_state(state).reverse!
      end

      # Defines the instance variables that should <em>not</em> be copied to the 
      # View instance.
      def protected_instance_variables  
        ['@parent_controller'] 
      end

    end

    module ClassMethods

      # Return the default view for the given state on this cell subclass.
      # This is a file with the name of the state under a directory with the
      # name of the cell followed by a template extension.
      def view_for_state(state)
        "#{cell_name}/#{state}"
      end

      # Find a possible template for a cell's current state.  It tries to find a
      # template file with the name of the state under a subdirectory
      # with the name of the cell under the <tt>app/cells</tt> directory.
      # If this file cannot be found, it will try to call this method on
      # the superclass.  This way you only have to write a state template
      # once when a more specific cell does not need to change anything in
      # that view.
      def find_class_view_for_state(state)
        return [view_for_state(state)] if superclass == Cell::Base

        superclass.find_class_view_for_state(state) << view_for_state(state)
      end


    end

  end
end
