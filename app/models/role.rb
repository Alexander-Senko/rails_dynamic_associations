class Role < ActiveRecord::Base
	has_many :relations

	validates :name, presence: true, uniqueness: true

	scope :named, -> (*names) {
		where name: names.flatten.map(&:to_s)
	}

	scope :available, -> {
		with_relations { Relation.of_abstract }
	}

	scope :in, -> (object) {
		with_relations { Relation.to object }
	}

	scope :for, -> (subject) {
		with_relations { Relation.of subject }
	}

	def self.find_or_create_named *names
		names.flatten!
		names.compact!

		(existing = named(names)).all +
			(names - existing.map(&:name)).map { |name|
				create name: name
			}
	end

	private

	def self.with_relations &block
		joins(:relations).merge(
			yield
		).uniq
	end
end
