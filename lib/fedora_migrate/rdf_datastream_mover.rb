module FedoraMigrate
  class RDFDatastreamMover < Mover

    def migrate
      Logger.info "converting datastream '#{source.dsid}' to RDF"
      before_rdf_datastream_migration
      migrate_rdf_triples
      after_rdf_datastream_migration
      save
    end

    def migrate_rdf_triples
      target.resource << updated_graph
    end

    private

      def updated_graph
        reader.new(updated_datastream_content)
      end

      def updated_datastream_content
        correct_encoding(datastream_content).gsub(/<.+#{source.pid}>/,"<#{target.uri}>")
      end

      def datastream_content
        source.content
      end

      # Scholarsphere has some ISO-8859 encoded data, which violates the NTriples spec.
      # Here we correct that.
      def correct_encoding(input)
        input.force_encoding(Encoding::ISO_8859_1).encode!(Encoding::UTF_8)
      end

      def reader
        RDF::Reader.for(:ntriples)
      end
  end
end
