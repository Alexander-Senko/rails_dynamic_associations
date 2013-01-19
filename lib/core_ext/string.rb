##
# TODO: refactor
#
class String
	def passivize
		sub(/(e?d?|[eo]r|ant)$/, 'ed')
	end unless method_defined? :passivize
end
