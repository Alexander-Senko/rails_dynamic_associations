ActiveSupport.on_load :model_class do
	for type in [ :source, :target ] do
		for relation in Relation.abstract.send({
			source: :to,
			target: :of,
		}[type], self).select(&:"#{type}_type") do
			setup_relation relation.send("#{type}_type").constantize, type, relation.role do |association|
				attr_accessible "#{association.to_s.singularize}_ids"
			end
		end
	end if self != Relation and Relation.table_exists? # needed for DB migrations & schema initializing
end
