# DSL to be included into a model
# To activate, simply
#
# class Model < Granite::ORM::Base
#   include Query::BuilderMethods
# end
module Query::BuilderMethods
  def __builder
    Builder(self).new
  end

  def count : Int32
    __builder.count
  end

  def where(**match_data) : Builder
    __builder.where **match_data
  end
end
