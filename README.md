# About

## Docker build

```bash
sudo -E docker build \
    --build-arg CONAN_EXTRA_REPOS="conan-local http://10.108.8.182:8081/artifactory/api/conan/conan False" \
    --build-arg CONAN_EXTRA_REPOS_USER="user -p password1 -r conan-local admin" \
    --build-arg CONAN_INSTALL="conan install --profile gcc --build missing" \
    --build-arg CONAN_CREATE="conan create --profile gcc --build missing" \
    --build-arg CONAN_UPLOAD="conan upload --all -r=conan-local -c --retry 3 --retry-wait 10 --force" \
    --build-arg BUILD_TYPE=Debug \
    -f conan_build_env.Dockerfile --tag conan_build_env . --no-cache
```

## Note

It is local build env, use it only in developer machines!
