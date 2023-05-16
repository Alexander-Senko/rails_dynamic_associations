module RailsDynamicAssociations
	module Config
		module Naming
			def shortcuts
				config :shortcut
			end

			def selfed
				config :selfed
			end

			def recursive
				config.each_with_object({}) do |(key, value), hash|
					hash[
						value[:selfed].to_s.pluralize.to_sym
					] = value[:recursive]
				end
			end

			def opposite direction
				find { |d| d != direction }
			end

			def opposite_shortcuts
				shortcuts.each_with_object({}) do |(key, value), hash|
					hash[key] = shortcuts.values.find do |v|
						v != value
					end
				end
			end

			private

			def config section = nil
				if section
					config.each_with_object({}) do |(key, value), hash|
						hash[key] = value[section]
					end
				else
					Config.association_names[:directions] # TODO: DRY
				end
			end
		end

		private

		module_function

		def association_names
			Engine.config.names
		end

		def association_directions
			@association_directions ||=
				association_names[:directions].keys.tap do |directions|
					class << directions
						include Naming
					end
				end
		end

		def actor_models
			@actor_models ||=
					Engine.config.actor_model_names
							.filter_map &:safe_constantize
		end
	end
end
