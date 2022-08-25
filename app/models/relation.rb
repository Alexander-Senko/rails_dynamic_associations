class Relation < ActiveRecord::Base
	belongs_to :source, polymorphic: true, optional: true
	belongs_to :target, polymorphic: true, optional: true
	belongs_to :role,                      optional: true

	delegate :name, to: :role, allow_nil: true

	default_scope {
		references(:roles).includes :role
	}

	association_directions.shortcuts.each &-> ((association, method)) do
		scope "#{method}_abstract", -> (object = nil) {
			if object then
				send("#{method}_abstract").
					send method, object
			else
				where "#{association}_id" => nil
			end
		}

		scope "#{method}_general", -> {
			send("#{method}_abstract").
				where "#{association}_type" => nil
		}

		scope method, -> (object) {
			case object
			when nil then
				# all
			when Symbol then
				send "#{method}_#{object}"
			when Class then
				where "#{association}_type" => object.base_class.name
			else
				where "#{association}_type" => object.class.base_class.name,
				      "#{association}_id"   => object.id
			end
		}
	end

	scope :abstract, -> {
		of_abstract.to_abstract
	}

	scope :applied, -> {
		where.not source_id: nil,
		          target_id: nil
	}

	scope :named, -> (*names) {
		case names
		when [[]] then # i.e. `named []`
			# all
		when []   then # i.e. `named`
			where.not role_id: nil
		else
			with_roles { named *names }
		end
	}

	def self.with_roles &block
		joins(:role).merge(
			Role.instance_eval &block
		).uniq
	end

	def self.seed source, target, roles = nil
		(roles.present? ? Role.find_or_create_named(roles) : [ nil ]).map do |role|
			create source_type: source,
			       target_type: target,
			       role:        role
		end
	end


	def name= role_name
		self.role = role_name &&
			Role.find_or_initialize_by(name: role_name)
	end

	def abstract?
		not (source_id or target_id)
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
