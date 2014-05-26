class Role < ActiveRecord::Base
	has_many :relations

	validates :name, presence: true, uniqueness: true

	scope :named, -> (*names) {
		where name: names.flatten.map(&:to_s)
	}

	scope :available, -> {
		includes(:relations).
			where relations: { id: Relation.of_abstract } # TODO: simplify
	}

	scope :in, -> (object) {
		where relations: { id: Relation.to(object) } # TODO: simplify
	}

	scope :for, -> (subject) {
		where relations: { id: Relation.of(subject) } # TODO: simplify
	}

	def self.find_or_create_named *names
		names.flatten!
		names.compact!

		(existing = named(names)).all +
			(names - existing.map(&:name)).map { |name|
				create name: name
			}
	end
end
