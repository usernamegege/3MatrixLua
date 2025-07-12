# Contributing to 3MatrixLua 🤝

First off, thanks for taking the time to contribute! You're awesome! 🎉

## Code of Conduct

Remember the BRO License philosophy: **Be excellent to each other!** 🫶

## How Can I Contribute?

### 🐛 Reporting Bugs

Found something broken? Let us know!

**Before submitting:**
- Check if the issue already exists
- Try to reproduce it with minimal code

**Include:**
- Your OS and LuaJIT version
- Minimal code example
- What you expected vs what happened
- Any error messages

### 💡 Suggesting Features

Got a cool idea? We'd love to hear it!

**Good feature requests:**
- Explain the problem it solves
- Include example usage
- Consider if it fits the "pure Lua" philosophy

### 🔧 Pull Requests

1. Fork the repo
2. Create your feature branch: `git checkout -b my-cool-feature`
3. Make your changes
4. Test everything still works
5. Commit: `git commit -am 'Add cool feature'`
6. Push: `git push origin my-cool-feature`
7. Open a Pull Request

**PR Guidelines:**
- Keep it focused - one feature/fix per PR
- Update docs if needed
- Add examples if adding new features
- Make sure all examples still run
- Follow existing code style

## Code Style

We're pretty chill, but:
- Use clear variable names
- Comment tricky parts
- Keep functions focused
- Indent with 4 spaces
- No trailing whitespace

## Testing

Before submitting:
```bash
# Run all examples
for f in examples/*.lua; do
    echo "Testing $f..."
    luajit "$f" &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null
done
```

## Adding Examples

New examples should:
- Be self-contained
- Show one concept clearly
- Include comments
- Actually be fun!

## Questions?

Open an issue! We're here to help.

Remember: This is supposed to be fun! If you're not having fun, we're doing something wrong. 🎮