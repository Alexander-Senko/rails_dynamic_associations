require 'rails_dynamic_associations/active_record/associations'

ActiveSupport.on_load :active_record do
	include RailsDynamicAssociations::ActiveRecord::Associations
end
