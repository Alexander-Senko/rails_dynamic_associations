require 'active_support/concern'

module RailsDynamicAssociations::ActiveRecord
	module Associations
		extend ActiveSupport::Concern

		def relation_from source
			source_relations.where(source_type: source.class.base_class, source_id: source.id).first
		end

		def relation_to target
			target_relations.where(target_type: target.class.base_class, target_id: target.id).first
		end

		module ClassMethods
			protected

			def setup_relation target, type, role = nil
				unless (through_association = :"#{type}_relations").in? reflections then
					has_many through_association, as: ([:source, :target] - [type]).first, class_name: 'Relation'
				end

				with_options({
					through:     through_association,
					source:      type,
					source_type: target.base_class.name,
					class_name:  target.name,
				}) do |model|
					association = if target == self then
						type == :target ? 'parent' : 'child'
					else
						target.name.split('::').reverse.join
					end.tableize.to_sym

					unless association.in? reflections then
						model.has_many association unless role # TODO
						define_association_with_roles association
						yield association if block_given?
					end

					if role then
						association_with_role = if target == self || target <= User then # TODO: DRY!
							type == :target ? "#{role.name.passivize}_#{target.name.split('::').reverse.join}" : role.name
						else
							"#{type == :target ? role.name.passivize : role.name}_#{association}"
						end.tableize.to_sym

						model.has_many association_with_role, conditions: { relations: { role_id: role.id } }
						yield association_with_role if block_given?
					end
				end

				for association, method in {
					parents:  :ancestors,
					children: :descendants,
				} do
					define_recursive_methods association, method if association.in? reflections and not method_defined? method
				end
			end

			private

			def define_association_with_roles association
				redefine_method "#{association}_with_roles" do |*roles|
					send(association).where(
						relations: {
							role_id: Role.where(name: roles.flatten.map(&:to_s)).pluck(:id)
						}
					)
				end
			end

			def define_recursive_methods association, method, tree_method = "#{method.to_s.singularize}_tree", distance_method = "#{method}_with_distance"
				redefine_method tree_method do
					send(association).inject([]) { |tree, node|
						tree << node << node.send(tree_method)
					}.reject &:blank?
				end

				redefine_method distance_method do
					(with_distance = -> (level, distance) {
						if level.is_a? Array then
							level.inject(ActiveSupport::OrderedHash.new) { |hash, node|
								hash.merge with_distance[node, distance.next]
							}
						else
							{ level => distance }
						end
					})[send(tree_method), 0]
				end

				redefine_method method do
					send(tree_method).flatten
				end
			end
		end
	end
end
