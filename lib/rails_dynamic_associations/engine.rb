module RailsDynamicAssociations
	class Engine < ::Rails::Engine
		isolate_namespace RailsDynamicAssociations

		config.names = {
			directions: {
				source: {
					shortcut:  :of,
					selfed:    :child,
					recursive: :descendants,
				},
				target: {
					shortcut:  :to,
					selfed:    :parent,
					recursive: :ancestors,
				},
			},
		}

		config.actor_model_names = %w[
				User
		]
	end
end
