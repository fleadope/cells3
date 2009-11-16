module Cell
  # With initializer you can customize cells to use only chosen features.
  # Ie. you may want cells with support to filters and layouts but without
  # Caching.
  #
  # Cell::Initializer.run do |cell|
  #   cell.use_filters = true
  #   cell.use_layouts = true
  #   cell.use_caching = false
  # end
  #
  # TODO: Per cell initializers
  module Initializer 

    class << self
      
      def cells_dir
        File.join( 'app', 'cells' )
      end

      def cells_layouts_dir
        File.join( cells_dir, 'layouts' )
      end

      def run
        yield self
      end

      def use_layouts=(enable)
        use_feature(AbstractController::Layouts, enable)
      end

      def use_helpers=(enable)
        use_feature(AbstractController::Helpers, enable)
        #TODO: discuss we should enable ApplicationHelper by default
        #maybe introduce something like
        # cell.use_helpers ApplicationHelper, NewsHelper
        # cell.use_helpers :default
        # cell.use_helpers :all
        Cell::Base.helper ApplicationHelper 
      end

      def use_filters=(enable)
        use_feature(AbstractController::Callbacks, enable)
      end

      def use_caching=(enable)
        use_feature(Cell::Caching, enable)
      end

      private
      def use_feature(klass, enable)
        Cell::Base.send(:include, klass) if enable
      end

    end

  end

end
