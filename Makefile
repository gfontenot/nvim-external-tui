.PHONY: test test-unit test-integration docs

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

test-unit:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/unit/ {minimal_init = 'tests/minimal_init.lua'}"

test-integration:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/integration/ {minimal_init = 'tests/minimal_init.lua'}"

docs:
	lemmy-help lua/external-tui.lua > doc/external-tui.txt
