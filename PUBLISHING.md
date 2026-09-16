# Publishing to Hex.pm

This document describes how to publish the Feedly Elixir client to Hex.pm.

## Prerequisites

1. Ensure you have a Hex.pm account at https://hex.pm/signup
2. Authenticate with Hex.pm locally:
   ```bash
   mix hex.user auth
   ```

## Pre-publish Checklist

- [x] All tests passing (`mix test`)
- [x] Code compiles without warnings (`mix compile --warnings-as-errors`)
- [x] Documentation is complete (`mix docs`)
- [x] README.md has usage examples
- [x] LICENSE file present (BSD-3-Clause)
- [x] mix.exs configured for publication
- [x] Committed to GitHub at https://github.com/osintowl/feedly

## Build and Verify Package

1. Build the package:
   ```bash
   mix hex.build
   ```

2. Verify the package contents:
   - Check that all necessary files are included
   - Verify version number is correct (0.1.0)
   - Confirm license is BSD-3-Clause
   - Check GitHub links are correct

## Publish to Hex.pm

### First Time Publication

1. Publish the package:
   ```bash
   mix hex.publish
   ```

2. Review the package information displayed
3. Confirm publication when prompted
4. Package will be available at https://hex.pm/packages/feedly

### Updating Documentation Only

If you need to update docs without publishing a new version:
```bash
mix hex.publish docs
```

## Post-Publication

1. Verify package at https://hex.pm/packages/feedly
2. Check documentation at https://hexdocs.pm/feedly
3. Test installation in a new project:
   ```elixir
   # In mix.exs
   defp deps do
     [
       {:feedly, "~> 0.1.0"}
     ]
   end
   ```

## Version Updates

For future releases:

1. Update version in `mix.exs`
2. Update CHANGELOG.md (if created)
3. Commit version bump
4. Tag the release:
   ```bash
   git tag v0.1.1
   git push origin v0.1.1
   ```
5. Publish new version:
   ```bash
   mix hex.publish
   ```

## Troubleshooting

### Authentication Issues
```bash
mix hex.user auth
# Or if already authenticated:
mix hex.user whoami
```

### Build Fails
- Ensure all dependencies are fetched: `mix deps.get`
- Clean and rebuild: `mix clean && mix compile`
- Check for compilation warnings

### Package Rejected
- Verify package name is available on Hex.pm
- Ensure all required metadata is present in mix.exs
- Check that version follows semantic versioning

## Package Information

- **Name**: feedly
- **Version**: 0.1.0
- **License**: BSD-3-Clause
- **GitHub**: https://github.com/osintowl/feedly
- **Hex.pm**: https://hex.pm/packages/feedly (once published)
- **Docs**: https://hexdocs.pm/feedly (once published)

## Support

For issues or questions:
- GitHub Issues: https://github.com/osintowl/feedly/issues
- Hex.pm Support: https://hex.pm/docs/usage
