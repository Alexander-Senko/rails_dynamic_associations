require 'active_support/concern'

module RailsDynamicAssociations::ActiveRecord
	module Relations
		extend ActiveSupport::Concern

		class_methods do
			include RailsDynamicAssociations::Config

			def relations
				@relations ||=
						association_directions.to_h do
							[ _1, Relation.abstract.send(association_directions.shortcuts.opposite[_1], self) ]
						end
			end
		end

		module InstanceMethods # to include when needed
			include RailsDynamicAssociations::Config

			def related?(...)
				relations(...)
						.values
						.reduce(&:or)
						.any?
			end

			def related(...)
				relations(...)
						.flat_map do |direction, relations|
							relations
									.preload(direction)
									.map &direction
						end
						.uniq
			end

			def relations *roles, **options
				if (direction, scope = find_direction options)
					{
							direction => relations_to(direction)
									.try(association_directions.shortcuts[direction], scope) # filter by related objects
					}
				else # both directions
					association_directions.to_h { [ _1, relations_to(_1) ] }
				end
						.reject { _2.nil? }
						.transform_values { roles.any? ? _1.named(roles) : _1  } # filter by role
			end

			private

			def relations_to direction
				try "#{direction}_relations"
			end
		end
	end
end
