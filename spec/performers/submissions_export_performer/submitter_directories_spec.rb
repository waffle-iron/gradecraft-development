require "rails_spec_helper"

RSpec.describe "SubmissionsExportPerformer: student directory handling", type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::SubmissionsExport::SharedExamples
  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  let(:archive_root_dir) { Dir.mktmpdir }
  let(:students) { [ student1, student2, student3 ] }
  let(:stub_students) { performer.instance_variable_set(:@submitters, students) }

  let(:student1) { create(:user) }
  let(:student2) { create(:user, first_name: student1.first_name, last_name: student1.last_name) }
  let(:student3) { create(:user) }

  let(:student_dir_name1) { student1.student_directory_name_with_username }
  let(:student_dir_name2) { student2.student_directory_name_with_username }
  let(:student_dir_name3) { student3.student_directory_name }

  let(:student_dir_path1) { "#{archive_root_dir}/#{student_dir_name1}" }
  let(:student_dir_path2) { "#{archive_root_dir}/#{student_dir_name2}" }
  let(:student_dir_path3) { "#{archive_root_dir}/#{student_dir_name3}" }

  let(:student_dir_paths) { [ student_dir_path1, student_dir_path2, student_dir_path3 ] }
  let(:remove_student_dirs) do
    [ student_dir_path1, student_dir_path2 ].each do |dir_path|
      Dir.rmdir(dir_path) if Dir.exist?(dir_path)
    end
  end

  let(:make_student_dirs) do
    [ student_dir_path1, student_dir_path2, student_dir_path3 ].each do |dir_path|
      FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
    end
  end

  before(:each) do
    allow(performer).to receive(:archive_root_dir) { archive_root_dir }
  end

  describe "missing_student_directories" do
    subject { performer.instance_eval { missing_student_directories }}
    before(:each) do
      stub_students
      make_student_dirs
      remove_student_dirs
    end

    context "student directories are missing" do
      it "returns the names of the missing directories relative to the archive_root_dir" do
        expect(subject).to eq([student_dir_name1, student_dir_name2])
      end

      it "doesn't return the name of directories that are actually there" do
        expect(subject).not_to include(student_dir_name3)
      end
    end

    context "student directories have been created" do
      it "returns an empty array" do
        performer.instance_eval { create_submitter_directories }
        expect(subject).to be_empty
      end
      after { remove_student_dirs }
    end
  end

  describe "student_directories_created_successfully" do
    subject { performer.instance_eval { student_directories_created_successfully }}

    context "missing_student_directories is empty" do
      it "returns true" do
        allow(performer).to receive(:missing_student_directories) { [] }
        expect(subject).to be_truthy
      end
    end

    context "missing_student_directories are present" do
      it "returns false" do
        allow(performer).to receive(:missing_student_directories) { [student_dir_name1, student_dir_name2] }
        expect(subject).to be_falsey
      end
    end
  end

  describe "create_submitter_directories" do
    subject { performer.instance_eval { create_submitter_directories }}
    before(:each) { stub_students }

    it "calls Dir.mkdir once for each student in @students" do
      expect(Dir).to receive(:mkdir).with(student_dir_path1).once
      expect(Dir).to receive(:mkdir).with(student_dir_path2).once
      expect(Dir).to receive(:mkdir).with(student_dir_path3).once
      subject
    end

    it "creates the directories for each student" do
      student_dir_paths.each {|dir_path| expect(Dir).to receive(:mkdir).with(dir_path) }
      subject
    end

    it "actually creates the directories on disk for each student" do
      subject
      student_dir_paths.each {|dir_path| expect(Dir.exist?(dir_path)).to be_truthy }
    end

    after(:each) do
      remove_student_dirs
    end
  end

  describe "submitter_directory_path" do
    subject { performer.instance_eval { submitter_directory_path( @some_student ) }}
    before(:each) do
      performer.instance_variable_set(:@submitters, students)
      performer.instance_variable_set(:@some_student, student1)
    end

    it "returns the correct directory path" do
      expect(subject).to eq(student_dir_path1)
    end

    it "expands the path relative to the tmp_dir" do
      expect(File).to receive(:expand_path).with(student_dir_name1, archive_root_dir)
      subject
    end
  end

  describe "#submitter_directory_names" do
    subject { performer.instance_eval { submitter_directory_names }}
    before(:each) { stub_students }

    context "students have identical names" do
      it "appends the username to the student name key" do
        expect(subject[student1.id]).to eq(student_dir_name1)
        expect(subject[student2.id]).to eq(student_dir_name2)
      end
    end

    context "student name doesn't match any others" do
      it "just uses the student name without the username" do
        expect(subject[student3.id]).to eq(student_dir_name3)
      end
    end

    describe "caching" do
      it "doesn't have a cached result to begin with" do
        expect(student1).to receive(:same_name_as?).exactly(students.size).times
        subject
      end

      it "caches the result after one call" do
        subject
        expect(student1).not_to receive(:same_name_as?)
        subject
      end
    end

    it "sets the result to @submitter_directory_names" do
      subject
      expect(performer.instance_variable_get(:@submitter_directory_names)).to eq(subject)
    end
  end

  describe "#remove_empty_submitter_directories" do
    subject { performer.instance_eval { remove_empty_submitter_directories }}
    let(:student_with_empty_dir) { create(:user) }
    let(:student_with_files) { create(:user) }
    let(:empty_dir_path) { Dir.mktmpdir }
    let(:empty_dir) { Dir.mktmpdir }
    let(:dir_with_files) { Dir.mktmpdir }
    let(:students) {[ student_with_empty_dir, student_with_files ]}

    before(:each) do
      performer.instance_variable_set(:@students, students)
      allow(performer).to receive(:submitter_directory_path).with(student_with_empty_dir) { empty_dir }
      allow(performer).to receive(:submitter_directory_path).with(student_with_files) { dir_with_files }
      allow(performer).to receive(:submitter_directory_empty?).with(student_with_empty_dir) { true }
      allow(performer).to receive(:submitter_directory_empty?).with(student_with_files) { false }
    end

    context "student directory is empty" do
      it "calls Dir.delete on the student directory path" do
        expect(Dir).to receive(:delete).with(empty_dir)
        subject
      end

      it "actually deletes the directory" do
        subject
        expect(Dir.exist?(empty_dir)).to be_falsey
      end
    end

    context "student directory is not empty" do
      it "doesn't call Dir.delete on the directory" do
        expect(Dir).not_to receive(:delete).with(dir_with_files)
        subject
      end

      it "leaves the directory in place" do
        subject
        expect(Dir.exist?(dir_with_files)).to be_truthy
      end
    end
  end

  describe "#submitter_directory_empty?" do
    subject { performer.instance_eval { submitter_directory_empty?(@some_student) }}
    let(:student) { create(:user) }
    let(:student_directory) { Dir.mktmpdir }
    let(:visible_file_path) { File.expand_path("visible_file.txt", student_directory) }
    let(:hidden_file_path) { File.expand_path(".hidden_file", student_directory) }

    before(:each) do
      student_directory
      performer.instance_variable_set(:@some_student, student)
      allow(performer).to receive(:submitter_directory_path) { student_directory }
    end

    after(:each) { subject }

    describe "semantics" do
      before { allow(Dir).to receive(:entries) { [] }}
      it "should look for entries in the directory" do
        expect(Dir).to receive(:entries).with(student_directory)
      end

      it "should look in the student directory path for the given student" do
        expect(performer).to receive(:submitter_directory_path).with(student)
      end
    end

    context "the student directory doesn't have any files" do
      it "should be true" do
        expect(subject).to be_truthy
      end
    end

    context "the student directory has visible files" do
      before { RandomFile::TextFile.new(visible_file_path).write }
      it "should be false" do
        expect(subject).to be_falsey
      end
    end

    context "the student directory has hidden files" do
      before { RandomFile::TextFile.new(hidden_file_path).write }
      it "should be false" do
        expect(subject).to be_falsey
      end
    end
  end
end
