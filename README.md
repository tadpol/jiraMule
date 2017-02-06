# jiraMule

## Install

### From source
```
> bundler install
> rake install
```

### By Gem
```
> gem install JiraMule
```

## Setup

You need to set a few config keys before anyhting really works.

Globally:
```
jm config net.url <URL to your Jira> --user
jm config user.name <Your account name in Jira> --user
```

Then in each project directory:
```
jm config jira.project <Project ID>
```

(you could add that to your user config too if you wanted.)


#### Jira API Docs

[https://docs.atlassian.com/jira/REST/7.2.4/][]

