

class GitUtils

	def self.getVersion
		tag = `git for-each-ref --sort=taggerdate --format '%(refname)' refs/tags | head -1`.chomp
		return tag.split('/').last
	end
end

#  vim: set sw=4 ts=4 :
