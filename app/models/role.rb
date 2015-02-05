class Role < ActiveRecord::Base
	has_many :relations

	validates :name, presence: true, uniqueness: true

	scope :named, -> (*names) {
		where name: names.flatten.map(&:to_s)
	}

	scope :available, -> {
		with_relations { of_abstract }
	}

	scope :in, -> (object) {
		with_relations { to object }
	}

	scope :for, -> (subject) {
		with_relations { of subject }
	}

	def self.find_or_create_named *names
		names.flatten!
		names.compact!

		(existing = named(names)).to_a +
			(names - existing.map(&:name)).map { |name|
				create name: name
			}
	end

	def self.with_relations &block
		joins(:relations).merge(
			Relation.instance_eval &block
		).uniq
	end
end
