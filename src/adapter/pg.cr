require "./base"
require "pg"

# PostgreSQL implementation of the Adapter
class Granite::Adapter::Pg < Granite::Adapter::Base
  QUOTING_CHAR = '"'

  # remove all rows from a table and reset the counter on the id.
  def clear(table_name)
    statement = "DELETE FROM #{quote(table_name)}"

    log statement

    open do |db|
      db.exec statement
    end
  end

  # select performs a query against a table.  The table_name and fields are
  # configured using the sql_mapping directive in your model.  The clause and
  # params is the query and params that is passed in via .all() method
  def select(table_name, fields, clause = "", params = [] of DB::Any, &block)
    clause = _ensure_clause_template(clause)

    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
      stmt << " FROM #{quote(table_name)} #{clause}"
    end

    log statement, params

    open do |db|
      db.query statement, params do |rs|
        yield rs
      end
    end
  end

  # select_one is used by the find method.
  def select_one(table_name, fields, field, id, &block)
    statement = String.build do |stmt|
      stmt << "SELECT "
      stmt << fields.map { |name| "#{quote(table_name)}.#{quote(name)}" }.join(", ")
      stmt << " FROM #{quote(table_name)}"
      stmt << " WHERE #{quote(field)}=$1 LIMIT 1"
    end

    log statement, id

    open do |db|
      db.query_one? statement, id do |rs|
        yield rs
      end
    end
  end

  def insert(table_name, primary_name, fields, params)
    statement = String.build do |stmt|
      stmt << "INSERT INTO #{quote(table_name)} ("
      stmt << fields.map { |name| "#{quote(name)}" }.join(", ")
      stmt << ") VALUES ("
      stmt << fields.map { |name| "$#{fields.index(name).not_nil! + 1}" }.join(",")
      stmt << ") "
      stmt << "RETURNING"
      stmt << " #{primary_name}"
    end

    log statement, params

    open do |db|
      return db.scalar(statement, params)
    end
  end

  private def last_val
    return "SELECT LASTVAL()"
  end

  # This will update a row in the database.
  def update(table_name, primary_name, fields, params)
    statement = String.build do |stmt|
      stmt << "UPDATE #{quote(table_name)} SET "
      stmt << fields.map { |name| "#{quote(name)}=$#{fields.index(name).not_nil! + 1}" }.join(", ")
      stmt << " WHERE #{quote(primary_name)}=$#{fields.size + 1}"
    end

    log statement, params

    open do |db|
      db.exec statement, params
    end
  end

  # This will delete a row from the database.
  def delete(table_name, primary_name, value)
    statement = "DELETE FROM #{quote(table_name)} WHERE #{quote(primary_name)}=$1"

    log statement, value

    open do |db|
      db.exec statement, value
    end
  end

  private def _ensure_clause_template(clause)
    if clause.includes?("?")
      num_subs = clause.count("?")

      num_subs.times do |i|
        clause = clause.sub("?", "$#{i + 1}")
      end
    end

    clause
  end
end
