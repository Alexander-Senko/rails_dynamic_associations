class Relation < ActiveRecord::Base
	belongs_to :source, polymorphic: true
	belongs_to :target, polymorphic: true
	belongs_to :role

	delegate :name, to: :role, allow_nil: true

	scope :in, -> (target) {
		where({
			source_id:   nil,
		}.merge case target
		when :general then {
			target_type: nil,
			target_id:   nil,
		} when Class then {
			target_type: target.name,
			target_id:   nil,
		} else {
			target_type: target.class.name,
			target_id:   target.id,
		} end).includes(:role)
		}

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
