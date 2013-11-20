require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'


require 'debugger'
require 'active_support/inflector'


class SQLObject < MassObject

  extend ::Searchable
  extend ::Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    return "humans" if self.to_s == "Human"
    self.to_s.pluralize.underscore
  end

  def self.all
    items = DBConnection.execute(<<-SQL) 
    SELECT * 
    FROM #{table_name}
    SQL

    self.parse_all(items)

  end

  def self.find(id)
    items = DBConnection.execute(<<-SQL, id)   
      SELECT * 
      FROM #{table_name} 
      WHERE id = ? 
    SQL

    items.map! { |item| self.new(item) }
    return items[0] if items.count == 1
    items
  end

  def save
    if self.id == nil
      create
    else
      update
    end

  end

  private

    def create
      DBConnection.execute(<<-SQL, *attribute_values) 
      INSERT INTO #{self.class.table_name} (#{self.class.attributes.join(", ")})
      VALUES
      (#{(['?']* self.class.attributes.count).join(", ")})
      SQL

      self.class.find(DBConnection.last_insert_row_id)
    end

    def update
      attr_to_set = self.class.attributes.select { |attr_name| (attr_name != :id && attr_name != "id") }
      set_line = attr_to_set.map { |attr_name| "#{attr_name} = ?" }.join(", ")
      DBConnection.execute(<<-SQL, *attribute_values(false)) 
      UPDATE #{self.class.table_name} 
      SET #{set_line}
      WHERE id = #{self.id}
      SQL
      self.class.find(self.id)

    end

    def attribute_values(include_id = true)
      [].tap do |attr_values|
        self.class.attributes.each do |attr_name|
          next if attr_name == :id && include_id == false
          attr_values << self.instance_variable_get("@#{attr_name.to_s}")
        end
      end
    end

end


if __FILE__ == $PROGRAM_NAME

  class Cat < SQLObject
    set_table_name("cats")
    my_attr_accessible(:id, :name, :owner_id)
  end

  class Human < SQLObject
    set_table_name("humans")
    my_attr_accessible(:id, :fname, :lname, :house_id)
  end

  cats_db_file_name = File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
  DBConnection.open(cats_db_file_name)
  
  #p Cat.where(:name => "Breakfast")[0]
  #debugger
  p Cat.all

  debugger
  cat = Cat.all.first
  p cat



end
