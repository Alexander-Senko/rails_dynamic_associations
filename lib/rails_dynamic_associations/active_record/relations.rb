require 'active_support/concern'

module RailsDynamicAssociations::ActiveRecord
	module Relations
		extend ActiveSupport::Concern

		included do
			extend  ClassAndInstanceMethods
			include ClassAndInstanceMethods
		end

		module ClassMethods
			RailsDynamicAssociations.opposite_directions.each &-> (association, method) do
				define_method "#{association}_relations" do
					Relation.send method, self
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
						(RailsDynamicAssociations.directions.keys.map { |d| r.send d } - [ self ]).first
					}.uniq
			end

			protected

			# TODO: use keyword arguments
			# TODO: simplify
			def find_relations args = {}
				directions = RailsDynamicAssociations.directions

				# Rearrange arguments
				for direction, method in directions do
					args[direction] = args.delete method
				end

				relations = directions.keys.each_with_object({}) do |(direction), relations|
					relations[direction] = find_relations_with_direction(*[
						direction, args.include?(:as) ? [ args[:as] ].flatten : nil
					].compact)
				end

				if direction = directions.keys.find { |a| args[a] } then # direction specified
					relations[direction].send(
						directions[direction], args[direction] # apply a filtering scope
					)
				else # both directions
					relations.values.sum
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
