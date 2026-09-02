# Image Testing

This project uses a lightweight test discovery and execution system for verifying Docker images.

## How it works

**Test structure:**
- Tests live in `<image>/tests/` directories
- Test files are named `*_test.sh` (e.g., `tomcat_native_test.sh`)
- Each test script receives the image name as its first argument

**Automatic discovery:**
- `./test/verify.sh` discovers all test files and runs them
- For each test, it determines which bake target provides that image
- If the target is cache-only (like `tomcat_base`), it finds the first final target that inherits from it
- Tests run against real, runnable images (not intermediate/cache-only ones)
- Image references come from `docker buildx bake --print`, so matrix targets,
  `image_tag()` and the `REGISTRY`/`REGISTRY_NAMESPACE`/`TAG` variables resolve
  exactly as they do at build time

**Example test:**
```bash
#!/bin/bash
# tomcat/tests/tomcat_native_test.sh
IMAGE=$1
docker run --rm "$IMAGE" catalina.sh configtest 2>&1 | grep -q "Loaded Apache Tomcat Native library"
```

## Running tests

```bash
# Run all discovered tests
./test/verify.sh

# Tests will:
# 1. Discover all */tests/*_test.sh files
# 2. Map each to its bake target
# 3. Resolve that target's tag through bake
# 4. Execute the test
# 5. Report results
```

## Adding tests

1. Create a `tests/` directory in your image folder if it doesn't exist:
   ```bash
   mkdir -p myimage/tests
   ```

2. Write a test script (must be executable):
   ```bash
   # myimage/tests/my_feature_test.sh
   #!/bin/bash
   IMAGE=$1
   docker run --rm "$IMAGE" /verify-my-feature.sh
   ```

3. Make it executable:
   ```bash
   chmod +x myimage/tests/my_feature_test.sh
   ```

4. Run `./test/verify.sh` to test it

## Test requirements

- Tests must exit with `0` on success, non-zero on failure
- Tests receive the fully resolved image reference (`registry/namespace/image:version`) as the first argument
- Tests should be isolated and not depend on external state
- Keep tests fast—they run after every build

## Integration with CI

Add to your GitHub Actions workflow:

```yaml
- name: Run image tests
  run: ./test/verify.sh
```

Tests will automatically fail the workflow if any test fails.
