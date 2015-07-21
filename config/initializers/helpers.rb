ActiveSupport.on_load :active_record do
	include RailsDynamicAssociations::ActiveRecord::Associations
	include RailsDynamicAssociations::ActiveRecord::Relations
end
