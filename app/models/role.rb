class Role < ActiveRecord::Base
	has_many :relations

	validates :name, presence: true, uniqueness: true

	scope :named, -> (*names) {
		where name: names.flatten.map(&:to_s)
	}

	scope :in, -> (target) {
		joins(:relations).
			where relations: { id: Relation.of_abstract.to(target) } # TODO: simplify
	}

	def self.find_or_create_named *names
		names.flatten!.compact!

		(existing = named(names)).all +
			(names - existing.map(&:name)).map { |name|
				create name: name
			}
	end
end
