# Contributing to nvim-external-tui

Thank you for your interest in contributing!

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/gfontenot/nvim-external-tui.git
   cd nvim-external-tui
   ```

2. Install dependencies:
   - [Neovim](https://neovim.io/) >= 0.9.0
   - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for testing)

3. For generating documentation:
   - [lemmy-help](https://github.com/numToStr/lemmy-help): `cargo install lemmy-help --features=cli`

## Running Tests

```bash
# Run all tests
make test

# Run only unit tests
make test-unit

# Run only integration tests
make test-integration
```

## Code Style

This project uses [StyLua](https://github.com/JohnnyMorganz/StyLua) for Lua formatting:

```bash
stylua lua/ tests/
```

Configuration is in `.stylua.toml`.

## Generating Documentation

The vimdoc is generated from LuaLS annotations using lemmy-help:

```bash
make docs
```

## Pull Request Process

1. Fork the repository and create your branch from `main`
2. Add tests for any new functionality
3. Ensure all tests pass: `make test`
4. Format your code: `stylua lua/ tests/`
5. Update documentation if needed: `make docs`
6. Submit your pull request

## Type Annotations

This project uses LuaLS type annotations. When adding or modifying functions:

- Add `---@param` for parameters
- Add `---@return` for return values
- Use `---@private` for internal functions
- Define `---@class` for complex types

See existing code for examples.
