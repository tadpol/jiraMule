require 'octokit'

command 'github import' do |c|
  c.syntax = %{jm github import <issue id>}
  c.summary = %{Import a Github issue into Jira}

  c.action do |args, options|

    iid = args.shift

    okey = $cfg['github.token']
    if okey.nil? then
      say_error "Missing github token!"
      exit 2
    end

    oc = Octokit::Client.new(:access_token => okey)
    if oc.nil? then
      say_error "cannot create client"
      exit 3
    end
    oc.login

    repo = oc.repo $cfg['github.project']
    rel = repo.rels[:issues]
    gissue = rel.get(:uri=>{:number=>iid})
    if gissue.status != 200 then
      say_error "Failed to get issue: #{gissue}"
      exit 2
    end
    gissue = gissue.data

    jira = JiraMule::JiraUtils.new(args, options)
    # Create Issue
    it = jira.checkIssueType # TODO Look at github labels and pick issue type
    if it.nil? then
      say_error "Cannot make an Issue of type 'bug'"
      exit 3
    end

    by = gissue[:user]
    qubody = []
    qubody << %{From [#{by[:login]}|#{by[:html_url]}]:}
    qubody << '{quote}'
    qubody << gissue[:body]
    qubody << '{quote}'

    jissue = jira.createIssue(it.first[:name], gissue[:title], qubody.join("\n"))
    jira.verbose "Created #{jissue[:key]}"

    # Link
    jira.linkTo(jissue[:key], gissue[:html_url], gissue[:title])

  end
end
alias_command :ghi, 'github import'

#  vim: set ai et sw=2 ts=2 :
