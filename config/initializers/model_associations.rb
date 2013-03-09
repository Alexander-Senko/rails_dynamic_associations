ActiveSupport.on_load :model_class do
	for type in [ :source, :target ] do
		for relation in Relation.where({ "#{([ :source, :target ] - [ type ]).first}_type" => self,
			source_id: nil,
			target_id: nil,
		}).select(&:"#{type}_type") do
			setup_relation relation.send("#{type}_type").constantize, type, relation.role do |association|
				attr_accessible "#{association.to_s.singularize}_ids"
			end
		end
	end if Relation.table_exists? # needed for DB migrations & schema initializing
end
