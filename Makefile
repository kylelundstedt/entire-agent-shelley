.PHONY: check test test-real install uninstall

check:
	python3 -m py_compile entire-agent-shelley
	bash -n install.sh uninstall.sh test-shelley-live.sh

# Runs without requiring an Entire CLI installation.
test: check
	ENTIRE_SKIP_REAL=1 bash test-shelley-live.sh

# Requires Entire CLI and exercises checkpoint condensation.
test-real: check
	bash test-shelley-live.sh

install:
	./install.sh

uninstall:
	./uninstall.sh
