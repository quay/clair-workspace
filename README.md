This is a `go work` setup for easier testing of changes across repositiories in the Clair cinematic universe. If you're
unfamiliar with Go workspaces, [Get familiar with workspaces](https://go.dev/blog/get-familiar-with-workspaces) and [Tutorial: Getting started with
multi-module workspaces](https://go.dev/doc/tutorial/workspaces) are great resource, but a key feature is that modules
specified in `go.work` will override the individual `go.mod`, eliminating the need for you to create a `replace`
directive yourself.

You'll need `git`, `myrepos`, `gh` and `just`.

dnf:

	sudo dnf install -y git myrepos gh just

brew:

	brew install git myrepos gh just


Before you do anything, make sure you have forked `clair`, `claircore`, and `zlog` to your GitHub account.

The default setup creates a remote for the forked repo called `origin` and the fork repo called `fork`. If you'd
rather have the remote for the forked repo called `upstream` and the fork repo called `origin`, run `just patch-setup`
first.

To start, run `just setup`.

To then test a particular branch, run `just build <repo>:<ref>...`.

That is, whichever repo you'd like to move off `main`, then a git `ref` of the branch to use.
For example, to build with your version of `zlog` on the `test` branch, run:

	just build zlog:fork/test

The setup step uses this convention (without the patch):

 - The upstream repo is the remote `origin`
 - A `fork` remote is added based on the GitHub username reported by `gh`
 - The pull requests in `origin` are fetched to `pr/<number>`

For example, to test pull request #1120 to claircore, run:

	just build claircore:origin/pr/1120

The setup step uses this convention (with the patch):

 - The upstream repo is the remote `upstream`
 - A `origin` remote is added based on the GitHub username reported by `gh`
 - The pull requests in `upstream` are fetched to `pr/<number>`

For example, to test pull request #1120 to claircore, run:

	just build claircore:upstream/pr/1120

