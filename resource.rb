require 'mime-types'
require 'sequel'
require 'sqlite3'

DB = Sequel.sqlite

DB.create_table :resources do
  primary_key :id
  foreign_key :parent_id
  String      :name
  Boolean     :complete, default: true
end

class Resource < Sequel::Model
  
  plugin :validation_helpers
  plugin :boolean_readers
  
  self.strict_param_setting = false
  
  attr_reader :tempfile
  
  def tempfile=(value)
    @tempfile = value
    modified!
  end
  
  def offset
    new? ? 0 : path.size
  end
  
  def type
    new? ? 'application/octet-stream' : MIME::Types.type_for(path.to_s).first.simplified
  end
  
  def validate
    super
    validates_presence [:complete, :parent_id, :name, :tempfile]
  end
  
  def after_create
    super
    FileUtils.mkpath dir unless dir.exist?
    FileUtils.touch path
  end
  
  def after_save
    super
    
    return unless tempfile

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
    delete_path
    super
  end
  
  def delete_path
    FileUtils.rm_rf path
  end
  
  def extension
    File.extname(name)
  end
  
  def path
    dir + [id.to_s, extension].join
  end
  
  def dir
    Pathname(ENV['UPLOAD_PATH']).expand_path
  end
end

at_exit do
  Resource.destroy
end