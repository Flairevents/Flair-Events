# Automatically generate code to transfer various types of data between server/clients

require 'models'

namespace :serialization do
  task :generate_code => [:generate_export_code, :generate_import_code]

  # generate code used on server to export data to JSON
  task :generate_export_code do
    constants = ::Models.constants.select { |c| ::Models.const_get(c).is_a?(::Models::Base) }

    File.open(Rails.root.join('lib', 'models', 'export.rb'), 'w') do |code|
      code << "# Machine generated, do not edit\n"
      code << "# See lib/tasks/serialization.rake\n"
      code << "require 'models'\n"
      code << "require 'oj'\n"
      code << "module Models::Export\n"
      constants.sort.each do |const|
        model = ::Models.const_get(const)
        # Export all records of a certain type to JSON
        code << "def export_#{const.to_s.downcase}_data_to_array(last_time = nil, get_confidential_data = true, buffer='')\n"
        code << "  records = pg.exec(::Models::#{const.to_s}.build_select(last_time, get_confidential_data))\n"
        code << "  buffer << Oj.dump(records.values)\n"
        code << "end\n\n"
        # Export an ActiveRecord object to array (which Rails will convert to JSON)
        code << "def export_#{const.to_s.downcase}_object(object)\n"
        code << "  [\n"
        code << model.columns.map do |column|
          "    #{column.export_from_object_code('object')}"
        end.join(",\n")
        code << "\n  ]\n"
        code << "end\n\n"
      end
      # Export all records of all types to JSON
      code << "def export_all_data_to_hash(last_time = nil, get_confidential_data = true, buffer='')\n"
      code << "  buffer << '{'\n"
      last_const = constants.sort.last
      constants.sort.each do |const|
        model = ::Models.const_get(const)
        code << "  if !last_time\n" if !model.timestamped
        code << "  buffer << '\"#{model.table}\":'\n"
        code << "  export_#{const.to_s.downcase}_data_to_array(last_time, get_confidential_data, buffer)\n"
        code << "  buffer << ','\n" unless const == last_const
        code << "  end\n" if !model.timestamped
      end
      code << "  buffer << '}'\n"
      code << "end\n"
      code << "end\n"
    end
  end

  # generate code used on client to import JSON data
  task :generate_import_code do
    constants = ::Models.constants.select { |c| ::Models.const_get(c).is_a?(::Models::Base) }

    File.open(Rails.root.join('app', 'assets', 'javascripts', 'import.coffee'), 'w') do |code|
      code << "# Machine generated, do not edit\n"
      code << "# See lib/tasks/serialization.rake\n"
      constants.sort.each do |const|
        model = ::Models.const_get(const)
        # Convert a single JSON array to a JS object
        code << "window.import#{const.to_s}FromJSON = (array) ->\n"
        code << "  {\n"
        code << model.columns.map.with_index do |column, i|
          if column.type == 'date'
            "    #{column.attr_name}: (val = array[#{i}]; val && (ymd = val.split(/[- :\.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2]))))"
          elsif column.type == 'datetime'
            "    #{column.attr_name}: (val = array[#{i}]; val && (ymd = val.split(/[- :\.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5]))))"
          elsif column.type == 'object'
            "    #{column.attr_name}: JSON.parse(array[#{i}])"
          else
            "    #{column.attr_name}: array[#{i}]"
          end
        end.join(",\n")
        code << "\n  }\n\n"
      end
      # Convert all JSON arrays (tables) sent back by server
      # tables -> {name: [records], name: [records]...}
      code << "window.importTables = (tables, callback) ->\n"
      constants.sort.each do |const|
        model = ::Models.const_get(const)
        code << "  if records = tables['#{model.table}']\n"
        code << "    callback('#{model.table}', records.map(import#{const.to_s}FromJSON))\n"
      end
      code << "\n\n"
    end
  end
end
