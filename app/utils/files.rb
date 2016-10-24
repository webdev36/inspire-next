# methods to write files, useful for pulling out stuff to
# use in tests from production

require 'json'

class Files

  def self.json_write(file_path, item)
    ::File.open(file_path, 'w') do |f|
      f.write(item.to_json)
    end
  end

  def self.raw_write(file_path, item)
    ::File.open(file_path, 'w') do |f|
      f.write(item)
    end
  end

  def self.json_read(file_path)
    file = ::File.read(file_path)
    JSON.parse(file)
  end

  def self.raw_read(file_path)
    ::File.read(file_path)
  end

  def self.json_write_to_fixture_path(file_name, item)
    file_path = "#{fixture_path}#{file_name}"
    json_write(file_path, item)
  end

  def self.json_write_to_tmp_path(file_name, item)
    FileUtils.mkpath tmp_path unless Dir.exist? tmp_path
    file_path = "#{tmp_path}#{file_name}"
    json_write(file_path, item)
  end

  def self.write_to_tmp_path(file_name, item)
    FileUtils.mkpath tmp_path unless Dir.exist? tmp_path
    file_path = "#{tmp_path}#{file_name}"
    raw_write(file_path, item)
  end

  def self.json_read_from_fixture_path(file_name)
    file_path = "#{fixture_path}#{file_name}"
    json_read(file_path)
  end

  def self.json_read_from_tmp_path(file_name)
    file_path = "#{tmp_path}#{file_name}"
    json_read(file_path)
  end

  def self.marshal_write_to_fixture_path(file_name, item)
    file_path = "#{fixture_path}#{file_name}"
    obj = Marshal.dump(item)
    raw_write(file_path, obj)
  end

  def self.marshal_read_from_fixture_path(file_name)
    file_path = "#{fixture_path}#{file_name}"
    raw_obj = raw_read(file_path)
    Marshal.load(raw_obj)
  end

  def self.marshal_write_to_tmp_path(file_name, item)
    file_path = "#{tmp_path}#{file_name}"
    obj = Marshal.dump(item)
    raw_write(file_path, obj)
  end

  def self.marshal_read_from_tmp_path(file_name)
    file_path = "#{tmp_path}#{file_name}"
    raw_obj = raw_read(file_path)
    Marshal.load(raw_obj)
  end

  def self.fixture_path
    "#{Rails.root}/spec/fixtures/"
  end

  def self.tmp_path
    "#{Rails.root}/tmp/"
  end

  def self.json_fixture_path
    "#{Rails.root}/spec/fixtures/json/"
  end
end
