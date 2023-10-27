This is a `go work` setup for easier testing of changes across repositiories in the Clair cinematic universe.

You'll need `git`, `myrepos`, `gh` and `just`:

	sudo dnf install -y git myrepos gh just


To start, run `just setup`.

To then test a particular branch, run `just build <repo>:<ref>...`.

That is, whichever repo you'd like to move off `main`, then a git `ref` of the branch to use.
For example, to build with your version of `zlog` on the `test` branch, run:

	just build zlog:fork/test

The setup step uses this convention:

 - The upstream repo is the remote `origin`
 - A `fork` remote is added based on the GitHub username reported by `gh`
 - The pull requests in `origin` are fetched to `pr/<number>`

For example, to test pull request #1120 to claircore, run:

	just build claircore:origin/pr/1120
