ActiveSupport.on_load :model_class do
  next if     self == Relation
  next unless Relation.table_exists?

  setup_relations
end
