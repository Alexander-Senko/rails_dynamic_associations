require 'rails_model_load_hook'

require 'rails_dynamic_associations/version'
require 'rails_dynamic_associations/engine'
require 'core_ext/string'

module RailsDynamicAssociations
	autoload :Config,       'rails_dynamic_associations/config'
	autoload :ActiveRecord, 'rails_dynamic_associations/active_record'

	warn RailsDynamicAssociations::DEPRECATION_MESSAGE, category: :deprecated
end
