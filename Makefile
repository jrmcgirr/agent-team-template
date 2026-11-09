.PHONY: help test test-fast

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

test: ## Full test suite (CI runs this; run before every push)
	@./scripts/test.sh full

test-fast: ## Quick deterministic sample (run while working)
	@./scripts/test.sh fast
