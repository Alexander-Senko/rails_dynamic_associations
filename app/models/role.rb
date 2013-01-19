class Role < ActiveRecord::Base
	has_many :relations
	has_many :users, :through => :relations, :source => :source, :source_type => 'User'

	validates :name, :presence => true, :uniqueness => true

	scope :named, lambda { |*names| where :name.in => names.flatten }

	# TODO: make DRY with Relation.in
	scope :in, lambda { |target|
		joins(:relations).where(:relations => {
			:source_id   => nil,
		}.merge(case target
		when :general then {
			:target_type => nil,
			:target_id   => nil,
		} when Class then {
			:target_type => target.name,
			:target_id   => nil,
		} else {
			:target_type => target.class.name,
			:target_id   => target.id,
		} end))
	}
end
