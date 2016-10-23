# this class exports a user's project details, putting them into a large
# single JSON file in the tmp folder

class ImportSqlUserData

  def initialize(file_path, row_separator = '**EOL**')
    @file_path = file_path
    @error_rows = []
    @unsure_rows = []
    @row_separator = row_separator
  end

  # reads the data from the file, storing in the hash_data vaiable
  def raw_sql_data
    @raw_sql_data ||= begin
      Files.raw_read(@file_path).split(@row_separator)
    end
  end

  def sql_statements
    @sql_statements ||= begin
      Files.raw_read(@file_path).split(@row_separator)
    end
  end

  def sql_import
    count_ok = 0
    overall_counter = 0
    sql_statements.each do |stmt|
      overall_counter += 1
      begin
        resp = execute_statement(stmt)
        if resp.is_a?(PG::Result)
          count_ok += 1
        else
          @unsure_rows << {:result => resp, :statement => stmt }
        end
      rescue => e
        @error_rows << { :error => e, :statement => stmt, :row => overall_counter }
      end
    end
    {:errors => @error_rows, :unsure => @unsure_rows, :ok_count => count_ok,  :commands_count => overall_counter}
  end

  def execute_statement(stmt)
    ActiveRecord::Base.connection.execute(stmt)
  end

end
