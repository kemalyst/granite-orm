# Query runner which finalizes a query and runs it.
# This will likely require adapter specific subclassing :[.
module Granite::Query::Assembler
  class Postgresql(Model) < Base(Model)
    def add_parameter(value : DB::Any) : String
      @numbered_parameters << value
      "$#{@numbered_parameters.size}"
    end
  end
end
