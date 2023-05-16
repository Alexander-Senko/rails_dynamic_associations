require 'active_support/concern'

module RailsDynamicAssociations::ActiveRecord
	module Associations
		extend ActiveSupport::Concern

		module ClassMethods
			include RailsDynamicAssociations::Config

			protected

			def setup_relations
				relations.each do |type, relations|
					for relation in relations.select(&:"#{type}_type") do
						setup_relation type, relation.send("#{type}_type").constantize, relation.role
					end
				end
			end

			def setup_relation type, target = self, role = nil
				define_association type, target
				define_association type, target, role if role

				association_directions.recursive
					.select { |association, method| reflect_on_association association }
					.reject { |association, method| method_defined? method }
					.each   { |association, method| define_recursive_methods association, method }
			end

			def actor?
				actor_models.any? { self <= _1 }
			end

			private

			def define_relations_association type, target = self, role = nil
				relations_association_name(type, target, role).tap do |association|
					next if reflect_on_association association

					has_many association, role && -> { where role_id: role.id },
						as: association_directions.opposite(to: type), class_name: 'Relation'
				end
			end

			def define_association type, target = self, role = nil
				association_name(type, target, role).tap do |association|
					next if reflect_on_association association

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

			def relations_association_name type, target = self, role = nil
				:"#{role ? association_name(type, target, role).to_s.singularize : type}_relations"
			end

			def association_name type, target = self, role = nil
				if role then
					association_name_with_role    type, target, role
				else
					association_name_without_role type, target
				end.tableize.to_sym
			end

			def association_name_with_role type, target, role
				if target == self or target.actor?
					{
						source: role.name,
						target: "#{role.name.passivize}_#{target.name.split('::').reverse.join}",
					}[type]
				else
					"#{{
						source: role.name,
						target: role.name.passivize,
					}[type]}_#{association_name_without_role type, target}"
				end
			end

			def association_name_without_role type, target
				if target == self then
					association_directions.selfed[type].to_s
				else
					target.name.split('::').reverse.join
				end
			end
		end
	end
end
