require 'sequel'
require 'sqlite3'
require 'mime-types'

DB = Sequel.sqlite

DB.create_table :resources do
  primary_key :id
  String      :name
  Boolean     :complete, default: false
end

class Resource < Sequel::Model
  
  plugin :validation_helpers
  plugin :boolean_readers
  
  self.strict_param_setting = false
  
  attr_reader :tempfile, :offset
  
  def file=(value)
    self.name = value[:filename]
    @tempfile = value[:tempfile]
    modified!
  end
  
  def offset=(value)
    @offset = value.to_i
    modified!
  end
  
  def types
    return [] if new?
    MIME::Types.type_for(path.to_s).map(&:simplified)
  end
  
  def size
    return 0 if new?
    path.size
  end
  
  def validate
    super
    validates_presence [:name, :tempfile, :offset]
  end
  
  def after_create
    super
    FileUtils.mkpath dir unless dir.exist?
  end
  
  def after_save
    super
    path.open(File::CREAT|File::WRONLY) do |file|
      begin
        file.flock File::LOCK_EX
        file.seek offset, IO::SEEK_SET
        file.write tempfile.read(4096) until tempfile.eof?
      ensure
        file.flock File::LOCK_UN
      end
    end
  end
  
  def before_destroy
    FileUtils.rm_rf path
    super
  end
  
  def path
    dir + [id.to_s, File.extname(name)].join
  end
  
  def dir
    Pathname(ENV['UPLOAD_PATH']).expand_path
  end
end

at_exit do
  Resource.destroy
end