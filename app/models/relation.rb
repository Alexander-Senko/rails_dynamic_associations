class Relation < ActiveRecord::Base
	belongs_to :source, polymorphic: true
	belongs_to :target, polymorphic: true
	belongs_to :role

	delegate :name, to: :role, allow_nil: true

	for direction, attribute in {
		of: :source,
		to: :target,
	} do
		-> (direction, attribute) {
			scope "#{direction}_abstract", -> {
				where "#{attribute}_id" => nil
			}

			scope "#{direction}_general", -> {
				send("#{direction}_abstract").
					where "#{attribute}_type" => nil
			}

			scope direction, -> (object) {
				case object
				when Symbol then
					send "#{direction}_#{object}"
				when Class then
					send("#{direction}_abstract").
						where "#{attribute}_type" => object
				else
					where "#{attribute}_type" => object.class.name,
					      "#{attribute}_id"   => object.id
				end
			}
		}.(direction, attribute)
	end

	scope :abstract, -> {
		of_abstract.to_abstract
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
