require 'active_support/concern'

module RailsDynamicAssociations::ActiveRecord
	module Relations
		extend ActiveSupport::Concern

		included do
			extend  ClassAndInstanceMethods
			include ClassAndInstanceMethods
		end

		module ClassMethods
			include RailsDynamicAssociations::Config

			def relations
				@relations ||=
						association_directions.to_h do
							[ _1, Relation.abstract.send(association_directions.shortcuts.opposite[_1], self) ]
						end
			end
		end

		module ClassAndInstanceMethods
			def relative? args = {}
				find_relations(args).
					present?
			end

			def relatives args = {}
				find_relations(args).
					map { |r|
						# TODO: optimize queries
						(association_directions.map { |d| r.send d } - [ self ]).first
					}.uniq
			end

			protected

			# TODO: use keyword arguments
			def find_relations args = {}
				# Rearrange arguments
				for direction, method in association_directions.shortcuts do
					args[direction] = args.delete method if
						method.in? args
				end

				roles = :as.in?(args) ?
					[ args[:as] ].flatten :
					[]

				if direction = association_directions.find { |a| a.in? args } then # direction specified
					find_relations_with_direction(direction, roles).send(
						association_directions.shortcuts[direction], args[direction] # apply a filtering scope
					)
				else # both directions
					association_directions.map do |direction|
						find_relations_with_direction direction, roles
					end.sum
				end
			end

			private

			def find_relations_with_direction direction, roles = []
				if respond_to? association = "#{direction}_relations" then
					send(association).named roles
				else
					Relation.none
				end
			end
		end
	end
end
