require 'rails_model_load_hook'

require 'rails_dynamic_associations/engine'
require 'core_ext/string'

module RailsDynamicAssociations
	autoload :Config,       'rails_dynamic_associations/config'
	autoload :ActiveRecord, 'rails_dynamic_associations/active_record'
end
