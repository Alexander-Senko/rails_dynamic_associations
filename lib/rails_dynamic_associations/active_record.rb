require 'rails_dynamic_associations/active_record/associations'
require 'rails_dynamic_associations/active_record/relations'

ActiveSupport.on_load :active_record do
	include RailsDynamicAssociations::ActiveRecord::Associations
	include RailsDynamicAssociations::ActiveRecord::Relations
end
