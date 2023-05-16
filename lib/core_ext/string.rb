##
# TODO: refactor
#
class String
	def passivize
		sub(/(e?d?|ing|[eo]r|ant|(t)ion)$/, '\\2ed')
	end unless method_defined? :passivize
end
