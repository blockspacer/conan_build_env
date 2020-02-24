# About

## Docker build

```bash
export MY_IP=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')
sudo -E docker build \
    --build-arg CONAN_INSTALL="conan install --profile gcc --build missing" \
    --build-arg CONAN_CREATE="conan create --profile gcc --build missing" \
    --build-arg CONAN_UPLOAD="conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force" \
    --build-arg BUILD_TYPE=Debug \
    -f conan_build_env.Dockerfile --tag conan_build_env . --no-cache
```

## Note

It is local build env, use it only in developer machines!
