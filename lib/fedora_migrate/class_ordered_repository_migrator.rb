module FedoraMigrate
  class ClassOrderedRepositoryMigrator < RepositoryMigrator

    def migrate_objects
      class_order.each do |klass|
        @source_objects = nil
        source_objects(klass).each do |object|
          @source = object
          migrate_current_object(klass)
        end
      end
      report.reload
    end

    def migrate_relationships
      return "Relationship migration skipped because migrator invoked in single pass mode." if single_pass?
      super
    end

    def migrate_current_object(klass)
      return unless migration_required?
      initialize_report
      migrate_object(klass)
    end

    def source_objects(klass)
      @source_objects ||= FedoraMigrate.source.connection.search(nil).collect { |o| qualifying_object(o, klass) }.compact
    end

    private

      def migrate_object(klass)
        return super unless reassign_ids?
        result.object = FedoraMigrate::ObjectMover.new(source, klass.new, options).migrate
        result.status = true
      rescue StandardError => e
        result.object = e.inspect
        result.status = false
      ensure
        report.save(source.pid, result)
      end

      def class_order
        @options[:class_order]
      end

      def single_pass?
        !!@options[:single_pass]
      end

      def reassign_ids?
        !!@options[:reassign_ids]
      end

      def qualifying_object(object, klass)
        name = object.pid.split(/:/).first
        return object if (name.match(namespace) && object.models.include?("info:fedora/afmodel:#{klass.name.gsub(/(::)/, '_')}"))
      end
  end
end
