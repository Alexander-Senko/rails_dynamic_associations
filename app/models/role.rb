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
end
