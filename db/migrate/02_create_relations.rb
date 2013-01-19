class CreateRelations < ActiveRecord::Migration
	def change
		create_table :relations do |t|
			t.references :source, :polymorphic => { :default => 'User' }
			t.references :target, :polymorphic => true
			t.references :role

			t.timestamps
		end

		add_index :relations, [ :source_id, :source_type, :target_id, :target_type, :role_id ], :unique => true,
		          :name => 'index_relations_on_source_and_target_and_role'
	end
end
