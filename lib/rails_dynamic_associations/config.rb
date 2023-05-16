module RailsDynamicAssociations
	module Config
		module Naming
			def shortcuts
				@shortcuts ||=
						config(:shortcut).tap do |shortcuts|
							def shortcuts.opposite to: nil
								if to
									values.reject { _1 == to }.sole
								else
									transform_values { opposite to: _1 }
								end
							end
						end
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

			def opposite to:
				reject { _1 == to }.sole
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

		def find_direction options
			normalize(options)
					.find { _1.in? association_directions }
		end

		def normalize options
			options.tap do |options|
				association_directions.shortcuts
						.select { _2.in? options }
						.each { options[_1] = options.delete _2 }
			end
		end
	end
end
