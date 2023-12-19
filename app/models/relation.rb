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
			when ActiveRecord::Base, nil
				where association => object
			when Class
				where "#{association}_type" => object.ancestors.select { _1 <= object.base_class }.map(&:name)
			when ActiveRecord::Relation
				send(method, object.klass)
						.where "#{association}_id" => object
			when Symbol
				send "#{method}_#{object}"
			else
				raise ArgumentError, "no relations for #{object.inspect}"
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
		when [] # i.e. `named`
			where.associated :role
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
			create role: role do
				_1[:source_type] = source
				_1[:target_type] = target
			end
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
