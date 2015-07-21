require 'rails_model_load_hook'

require 'rails_dynamic_associations/engine'
require 'core_ext/string'

module RailsDynamicAssociations
	mattr_accessor :directions,
	               :self_referential,
	               :self_referential_recursive

	self.directions = {
		source: :of,
		target: :to,
	}

	self.self_referential = {
		source: :child,
		target: :parent,
	}

	self.self_referential_recursive = {
		parents:  :ancestors,
		children: :descendants,
	}

	def self.opposite_directions
		directions.each_with_object({}) do |(key, value), hash|
			hash[key] = directions.values.find do |v|
				v != value
			end
		end
	end

	autoload :ActiveRecord, 'rails_dynamic_associations/active_record'
end
