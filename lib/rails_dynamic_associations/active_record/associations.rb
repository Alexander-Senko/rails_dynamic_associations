require 'active_support/concern'

module RailsDynamicAssociations::ActiveRecord
	module Associations
		extend ActiveSupport::Concern

		module ClassMethods
			protected

			def setup_relation type, target = self, role = nil
				define_association type, target
				define_association type, target, role if role

				for association, method in RailsDynamicAssociations.self_referential_recursive do
					define_recursive_methods association, method if association.in? reflections and not method_defined? method
				end
			end

			private

			def define_relations_association type, target = self, role = nil
				:"#{role ? association_name(type, target, role).to_s.singularize : type}_relations".tap do |association|
					unless association.in? reflections then
						has_many association, role && -> { where role_id: role.id },
						         as: (RailsDynamicAssociations.directions.keys - [type]).first, class_name: 'Relation'
					end
				end
			end

			def define_association type, target = self, role = nil
				unless (association = association_name(type, target, role)).in? reflections then
					has_many association,
					         through:     define_relations_association(type, target, role),
					         source:      type,
					         source_type: target.base_class.name,
					         class_name:  target.name

					define_association_with_roles association unless role

					yield association if block_given?
				end
			end

			def define_association_with_roles association
				redefine_method "#{association}_with_roles" do |*roles|
					send(association).where(
						relations: {
							role_id: Role.named(roles).pluck(:id)
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

			def association_name type, target = self, role = nil
				if role then
					if target == self || target <= User then
						{
							source: role.name,
							target: "#{role.name.passivize}_#{target.name.split('::').reverse.join}",
						}[type]
					else
						"#{{
							source: role.name,
							target: role.name.passivize,
						}[type]}_#{association_name type, target}"
					end
				else
					if target == self then
						RailsDynamicAssociations.self_referential[type].to_s
					else
						target.name.split('::').reverse.join
					end
				end.tableize.to_sym
			end
		end
	end
end
