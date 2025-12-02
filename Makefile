.PHONY: test test-unit test-integration

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

test-unit:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/unit/ {minimal_init = 'tests/minimal_init.lua'}"

test-integration:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/integration/ {minimal_init = 'tests/minimal_init.lua'}"
