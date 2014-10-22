require 'spec_helper'

describe "Migrating an object" do

  let(:source)    { FedoraMigrate.source.connection.find("sufia:rb68xc089") }
  let(:fits_xml)  { load_fixture("sufia-rb68xc089-characterization.xml").read }

  context "when the target model is provided" do

    let(:mover) { FedoraMigrate::ObjectMover.new source, ExampleModel::MigrationObject.new }
    
    subject do
      mover.migrate
      mover.target
    end

    it "should migrate the entire object" do
      expect(subject.content.versions.count).to eql 4
      expect(subject.thumbnail.mime_type).to eql "image/jpeg"
      expect(subject.thumbnail.versions.count).to eql 0
      expect(subject.characterization.content).to be_equivalent_to(fits_xml)
      expect(subject.characterization.versions.count).to eql 0
      expect(subject).to be_kind_of ExampleModel::MigrationObject
    end

  end

  context "when we have to determine the model" do

    let(:mover) { FedoraMigrate::ObjectMover.new source }

    context "and it is defined" do
      subject do
        class GenericFile < ExampleModel::MigrationObject; end
        mover.migrate
        mover.target
      end

      it "should migrate the entire object" do
        expect(subject.content.versions.count).to eql 4
        expect(subject.thumbnail.mime_type).to eql "image/jpeg"
        expect(subject.thumbnail.versions.count).to eql 0
        expect(subject.characterization.content).to be_equivalent_to(fits_xml)
        expect(subject.characterization.versions.count).to eql 0
        expect(subject).to be_kind_of GenericFile
      end
    end

    context "and it is not defined" do
      before do
        Object.send(:remove_const, :GenericFile) if defined?(GenericFile)
      end
      it "should fail" do
        expect{mover.migrate}.to raise_error(NameError)
      end
    end

  end

  context "when the object has an ntriples datastream" do

    context "and we want to convert it to a provided model" do
      let(:mover) { FedoraMigrate::ObjectMover.new(source, ExampleModel::RDFObject.new, {convert: "descMetadata"}) }
    
      subject do
        mover.migrate
        mover.target
      end

      it "should migrate the entire object" do
        expect(subject.content.versions.count).to eql 4
        expect(subject.thumbnail.mime_type).to eql "image/jpeg"
        expect(subject.thumbnail.versions.count).to eql 0
        expect(subject.characterization.content).to be_equivalent_to(fits_xml)
        expect(subject.characterization.versions.count).to eql 0
        expect(subject).to be_kind_of ExampleModel::RDFObject
        expect(subject.title).to eql(["world.png"])
      end

    end

    context "and we want to convert multiple datastreas" do

      # Need a fixture with two different datastreams for this test to be more effective      
      let(:mover) { FedoraMigrate::ObjectMover.new(source, ExampleModel::RDFObject.new, {convert: ["descMetadata", "descMetadata"]}) }
    
      subject do
        mover.migrate
        mover.target
      end

      it "should migrate all the datastreams" do
        expect(subject.title).to eql(["world.png"])
      end
    end

  end

end