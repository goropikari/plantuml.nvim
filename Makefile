.PHONY: fmt
fmt:
	stylua -g '*.lua' -- .

.PHONY: lint
lint:
	typos -w

.PHONY: check
check: lint fmt

.PHONY: dev-up
dev-up:
	devcontainer up --workspace-folder=.

.PHONY: dev-up-new
dev-up-new:
	devcontainer up --workspace-folder=. --remove-existing-container

.PHONY: dev-exec
dev-exec:
	devcontainer exec --workspace-folder=. bash
