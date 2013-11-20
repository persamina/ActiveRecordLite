require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

require 'debugger'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table
    @other_class_name.constantize.table_name
  end
end

class BelongsToAssocParams < AssocParams
  attr_accessor :name, :other_class_name, :primary_key, :foreign_key 

  def initialize(name, params)
    @name = name
    @other_class_name = params[:class_name] || name.to_s.camelize
    @primary_key = params[:primary_key] || "id" 
    @foreign_key = params[:foreign_key] || "#{name.to_s.underscore}_id"
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_accessor :name, :other_class_name, :primary_key, :foreign_key 
  def initialize(name, params, self_class)
    @name = name
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || "id" 
    @foreign_key = params[:foreign_key] || "#{self_class.to_s.underscore.underscore}_id"
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params
  end

  def belongs_to(name, params = {})
    @assoc_params ||= {}

    all_params = BelongsToAssocParams.new(name, params) 
    define_method(name) do 
      results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{all_params.other_class.table_name}
      WHERE #{all_params.primary_key}  = #{self.send(all_params.foreign_key)} 
      SQL
      all_params.other_class.parse_all(results)[0]
    end
    debugger
    @assoc_params[name] = all_params
  end

  def has_many(name, params = {})
    all_params = HasManyAssocParams.new(name, params, self.to_s)
    define_method(name) do 
      results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{all_params.other_class.table_name}
      WHERE #{all_params.foreign_key} = #{self.send(all_params.primary_key)} 
      SQL
      all_params.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      assoc1_params = self.class.assoc_params[assoc1]
      assoc2_params = assoc1_params.other_class.assoc_params[assoc2]
      debugger

      results = DBConnection.execute(<<-SQL)
      SELECT #{assoc2_params.other_class.table_name}.*
      FROM #{assoc2_params.other_class.table_name} JOIN #{assoc1_params.other_class.table_name}
      ON #{(assoc1_params.other_class.table_name)}.#{assoc2_params.foreign_key}
      = #{(assoc2_params.other_class.table_name)}.#{assoc2_params.primary_key}
      WHERE #{assoc1_params.other_class.table_name}.#{assoc1_params.primary_key} = #{self.owner_id}
      SQL

      debugger
      assoc2_params.other_class.parse_all(results)[0]

    end
  end
end


if __FILE__ == $PROGRAM_NAME

  cats_db_file_name =
  File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
  DBConnection.open(cats_db_file_name)

  class Cat < SQLObject
    set_table_name("cats")
    my_attr_accessible(:id, :name, :owner_id)

    belongs_to :human, :class_name => "Human", :primary_key => :id, :foreign_key => :owner_id
    #has_one_through :house, :human, :house
  end

  class Human < SQLObject
    set_table_name("humans")
    my_attr_accessible(:id, :fname, :lname, :house_id)

    has_many :cats, :foreign_key => :owner_id
    belongs_to :house
  end

  class House < SQLObject
    set_table_name("houses")
    my_attr_accessible(:id, :address, :house_id)
  end

  cat = Cat.find(1)
  debugger
  p cat
  p cat.human


end
