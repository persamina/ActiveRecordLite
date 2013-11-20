require_relative './db_connection'

require 'debugger'

module Searchable

  def where(params)
    key_line = params.keys.map { |attr_name| "#{attr_name} = ?" }.join(" AND ")
    values = params.values

    results = DBConnection.execute(<<-SQL, *values)
      SELECT *
      FROM #{table_name}
      WHERE #{key_line}
    SQL

    self.parse_all(results)
    #results.map! { |result| self.new(result) }
  end
end

if __FILE__ == $PROGRAM_NAME


end
