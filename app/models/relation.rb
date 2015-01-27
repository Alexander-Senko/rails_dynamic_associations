class Relation < ActiveRecord::Base
	belongs_to :source, polymorphic: true
	belongs_to :target, polymorphic: true
	belongs_to :role

	delegate :name, to: :role, allow_nil: true

	RailsDynamicAssociations.directions.each &-> (association, method) do
		scope "#{method}_abstract", -> (object = nil) {
			if object then
				send method, object
			else
				all
			end.
				where "#{association}_id"   => nil
		}

		scope "#{method}_general", -> {
			send("#{method}_abstract").
				where "#{association}_type" => nil
		}

		scope method, -> (object) {
			case object
			when Symbol then
				send "#{method}_#{object}"
			when Class then
				where "#{association}_type" => object.base_class
			else
				where "#{association}_type" => object.class.base_class,
				      "#{association}_id"   => object.id
			end
		}
	end

	scope :abstract, -> {
		of_abstract.to_abstract
	}

	def self.seed source, target, roles = nil
		(roles.present? ? by_roles(roles) : [ self ]).map do |scope|
			scope.create source_type: source,
			             target_type: target
		end
	end

	def self.by_roles *names
		Role.find_or_create_named(*names).
			map &:relations
	end


	def name= role_name
		self.role = role_name &&
			Role.find_or_initialize_by(name: role_name)
	end


	# Using polymorphic associations in combination with single table inheritance (STI) is
	# a little tricky. In order for the associations to work as expected, ensure that you
	# store the base model for the STI models in the type column of the polymorphic
	# association.
	for reflection in reflections.values.select { |r| r.options[:polymorphic] } do
		define_method "#{reflection.name}_type=" do |type|
			super type && type.to_s.classify.constantize.base_class.to_s
		end
	end
end
