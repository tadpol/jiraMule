require 'tempfile'
require 'zip'

command :attach do |c|
  c.syntax = 'jm attach [options] [key] [file...]'
  c.summary = 'Attach file to an Issue'
  c.description = 'Attach a file to an Issue'
  c.example 'Attach a file', %{jm attach BUG-1 foo.log}
	c.option '-z', '--zip', 'Zip the file[s] first'

  c.action do |args, options|
		options.default :zip => false

		jira = JiraUtils.new(args, options)
		key = args.shift

		# keys can be with or without the project prefix.
		key = jira.expandKeys([key]).first

		printVars(:key=>key, :files=>args)

		begin
			if options.zip then
				tf = Tempfile.new('zipped')
				begin
					tf.close
					Zip::File.open(tf.path, Zip::File::CREATE) do |zipfile|
						args.each do |file|
							if File.directory?(file) then
								Dir[File.join(file, '**', '**')].each do |dfile|
									zipfile.add(dfile, dfile)
								end
							else
								zipfile.add(file, file)
							end
						end
					end

					jira.attach(key, tf.path, 'application/zip', "#{Time.new.to_i}.zip")

				ensure
					tf.unlink
				end

			else
				args.each do |file|
					raise "Cannot send directories! #{file}" if File.directory?(file)
					raise "No such file! #{file}" unless File.exists? file
					mime=`file -I -b #{file}`
					mime='application/octect' if mime.nil?
					jira.attach(key, file, mime)
				end
			end

		rescue JiraUtilsException => e
			puts "= #{e}"
			puts "= #{e.request}"
			puts "= #{e.response}"
			puts "= #{e.response.inspect}"
			puts "= #{e.response.body}"
		rescue Exception => e
			puts e
		end

	end
end

#  vim: set sw=2 ts=2 :
