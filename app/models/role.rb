class Role < ActiveRecord::Base
	has_many :relations

	validates :name, presence: true, uniqueness: true

	scope :named, -> (*names) { where :name.in => names.flatten }

	# TODO: make DRY with Relation.in
	scope :in, -> (target) {
		joins(:relations).where(relations: {
			source_id:   nil,
		}.merge(case target
		when :general then {
			target_type: nil,
			target_id:   nil,
		} when Class then {
			target_type: target.name,
			target_id:   nil,
		} else {
			target_type: target.class.name,
			target_id:   target.id,
		} end))
	}
end