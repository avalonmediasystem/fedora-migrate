module FedoraMigrate
  class ClassOrderedRepositoryMigrator < RepositoryMigrator

    def migrate_objects
      class_order.each do |klass|
        @source_objects = nil
        source_objects(klass).each do |object|
          @source = object
          migrate_current_object
        end
      end
      report.reload
    end

    def migrate_relationships
      return "Relationship migration skipped because migrator invoked in single pass mode." if single_pass?
      super
    end

    def source_objects(klass)
      @source_objects ||= FedoraMigrate.source.connection.search(nil).collect { |o| qualifying_object(o, klass) }.compact
    end

    private

      def class_order
        @options[:class_order]
      end

      def single_pass?
        !!@options[:single_pass]
      end

      def qualifying_object(object, klass)
        name = object.pid.split(/:/).first
        return object if (name.match(namespace) && object.models.include?("info:fedora/afmodel:#{klass.name.gsub(/(::)/, '_')}"))
      end
  end
end
