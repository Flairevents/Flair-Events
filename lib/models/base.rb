# This is used when retrieving data for the Office Zone

module Models
  # For each data field used by the Office Zone, we need to know what it is called,
  #   how to retrieve it using SQL, how to retrieve it using Ruby (for an already-loaded
  #   ActiveRecord object), what its data type is, etc.
  # We keep this information together using ListColumn structs

  # Notes
  # :select       - used to build a SQL query which can retrieve value
  #                 (to bypass ActiveRecord, faster)
  # :attr_name    - name for the attribute in the Office Zone client code
  # :fn           - used to build Ruby code which can retrieve value from an ActiveRecord object
  #                 should evaluate to an object of a class matching the column type
  # :confidential - should this data only be accessible to managers?
  # :null         - can this attribute be NULL?

  ListColumn = Struct.new(:attr_name, :type, :select, :fn, :confidential, :null) do
    def initialize(attr_name, type, options={})
      super(attr_name, type)
      self.select       = options[:select]
      self.fn           = options[:fn]
      self.confidential = options[:confidential]
      self.null         = options[:null] || false
    end

    def export_from_record_code(variable, index)
      code = '(val = ' << variable << '[' << index.to_s << ']; '
      code << "val.nil? ? 'null' : " if self.null
      code << convert_column_value_code('val') << ')'
    end

    def export_from_object_code(variable)
      if self.type == 'time' || self.type == 'date'
        code = '(val = ' << (self.fn || variable + '.' + self.attr_name.to_s) << '; '
        code << 'val && ' if self.null
        code << convert_ruby_attribute_code('val') << ')'
      else
        self.fn || (variable + '.' + self.attr_name.to_s)
      end
    end

    # Ruby code which can be used to convert this column's value to JSON
    # (When retrieved using raw SQL)
    # We get numbers as Ruby Numerics, booleans as Ruby booleans, but dates/times
    #   are just strings
    def convert_column_value_code(variable)
      if self.type == 'number' || self.type == 'boolean'
        variable + '.to_s'
      else
        variable + '.inspect'
      end
    end

    # Ruby code which can be used to convert this column's value to JSON
    # (When retrieved through ActiveRecord)
    def convert_ruby_attribute_code(variable)
      if self.type == 'time'
        "\"\#{#{variable}.hour.to_s.rjust(2, '0')}:\#{#{variable}.min.to_s.rjust(2, '0')}\""
      elsif self.type == 'date'
        "\"\#{#{variable}.year}-\#{#{variable}.month}-\#{#{variable}.day}\""
      else
        variable
      end
    end
  end

  ListColumn::TYPES = %w(string number boolean time date datetime object).freeze

  class Base
    def initialize(table, columns, options={})
      unless columns.all? { |c| ListColumn::TYPES.include?(c.type) }
        raise "Invalid column type in #{columns.map(&:type).to_set}"
      end
      @table   = table
      @columns = columns.freeze
      @joins   = options[:joins] || []
      @where   = options[:where] || []
      @timestamped = options[:has_timestamps].nil? ? true : options[:has_timestamps]
    end

    attr_reader :table, :columns, :timestamped

    # Build SELECT clause SQL to retrieve all the needed fields from a table
    def build_select(last_time = nil, get_confidential_data = true)
      if last_time && !@timestamped
        # for tables which are not timestamped, this should never be called with a last_time
        raise "#{@table} has no timestamps, so we can't tell which records have been updated"
      end
      selected = @columns.map do |c|
        if get_confidential_data || !c.confidential
          if c.type == 'time' && !c.select
            "to_char(#{table}.#{c.attr_name}, 'HH24:MI') AS #{c.attr_name}"
          else
            "#{c.select || "#{table}.#{c.attr_name}"} AS #{c.attr_name}"
          end
        else
          "NULL"
        end
      end
      query = "SELECT #{selected.join(', ')} FROM #{@table}"
      @joins.each { |join| query << " " << join }
      where = @where.dup
      where << "#{@table}.updated_at >= #{db.quote(last_time)}" if last_time
      query << " WHERE " << where.join(' AND ') if where.present?
      query
    end
  end
end
