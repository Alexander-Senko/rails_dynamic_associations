ActiveSupport.on_load :model_class do
	for type in RailsDynamicAssociations.directions.keys do
		for relation in send("#{type}_relations").abstract.select(&:"#{type}_type") do
			setup_relation type, relation.send("#{type}_type").constantize, relation.role do |association|
				attr_accessible "#{association.to_s.singularize}_ids"
			end
		end
	end if self != Relation and Relation.table_exists? # needed for DB migrations & schema initializing
end
