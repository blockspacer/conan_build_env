# allows individual sections to be run by doing: docker build --target ...
FROM gaeus:cxx_build_env as conan_build_env
# NOTE: if not BUILD_GRPC_FROM_SOURCES, then script uses conan protobuf package
ARG BUILD_TYPE=Release
# NOTE: cmake from apt may be outdated
ARG CMAKE_FROM_APT="False"
ARG CMAKE="cmake"
ARG GIT="git"
ARG GIT_EMAIL="you@example.com"
ARG GIT_USERNAME="Your Name"
ARG APT="apt-get -qq --no-install-recommends"
ARG PROTOC="protoc"
ARG LS_VERBOSE="ls -artl"
ARG PIP="pip3"
# SEE: http://kefhifi.com/?p=701
ARG GIT_WITH_OPENSSL="True"
ARG CONAN="conan"
# Example: --build-arg CONAN_EXTRA_REPOS="conan-local http://localhost:8081/artifactory/api/conan/conan False"
ARG CONAN_EXTRA_REPOS=""
# Example: --build-arg CONAN_EXTRA_REPOS_USER="user -p password -r conan-local admin"
ARG CONAN_EXTRA_REPOS_USER=""
ARG GIT_CA_INFO=""
ENV LC_ALL=C.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    #TERM=screen \
    PATH=/usr/bin/:/usr/local/bin/:/go/bin:/usr/local/go/bin:/usr/local/include/:/usr/local/lib/:/usr/lib/clang/6.0/include:/usr/lib/llvm-6.0/include/:$PATH \
    LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH \
    GIT_AUTHOR_NAME=$GIT_USERNAME \
    GIT_AUTHOR_EMAIL=$GIT_EMAIL \
    GIT_COMMITTER_NAME=$GIT_USERNAME \
    GIT_COMMITTER_EMAIL=$GIT_EMAIL \
    WDIR=/opt \
    # NOTE: PROJ_DIR must be within WDIR
    PROJ_DIR=/opt/project_copy \
    # NOTE: PROJ_DIR must be within WDIR
    CA_PROJ_DIR=/opt/project_copy/.ca-certificates \
    # NOTE: PROJ_DIR must be within WDIR
    SCRIPTS_PROJ_DIR=/opt/project_copy/scripts \
    GOPATH=/go \
    CONAN_REVISIONS_ENABLED=1 \
    CONAN_PRINT_RUN_COMMANDS=1 \
    CONAN_LOGGING_LEVEL=10 \
    CONAN_VERBOSE_TRACEBACK=1

# create all folders parent to $PROJ_DIR
RUN set -ex \
  && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && \
  mkdir -p $WDIR
# NOTE: ADD invalidates the cache, COPY does not
COPY "scripts/" $SCRIPTS_PROJ_DIR/
COPY ".ca-certificates/"  $CA_PROJ_DIR/
WORKDIR $PROJ_DIR

RUN set -ex \
  && \
  $APT update \
  && \
  $APT install -y \
                    git \
  && \
  ($LS_VERBOSE /usr/local/lib/libprotobuf* || true) \
  && \
  ($LS_VERBOSE /usr/local/lib/libgrpc* || true) \
  && \
  ($PROTOC --version || true) \
  && \
  cd $PROJ_DIR \
  && \
  $LS_VERBOSE $PROJ_DIR \
  && \
  (cp $CA_PROJ_DIR/* /usr/local/share/ca-certificates/ || true) \
  && \
  (rm -rf $CA_PROJ_DIR || true) \
  && \
  if [ "$CMAKE_FROM_APT" != "True" ]; then \
    # Uninstall the default version provided by Ubuntu package manager, so we can install custom one
    ($APT purge -y cmake || true) \
    && \
    chmod +x $SCRIPTS_PROJ_DIR/install_cmake.sh \
    && \
    bash $SCRIPTS_PROJ_DIR/install_cmake.sh \
    ; \
  fi \
  && \
  if [ ! -z "$http_proxy" ]; then \
    echo 'WARNING: GIT sslverify DISABLED! SEE http_proxy IN DOCKERFILE' \
    && \
    ($GIT config --global http.proxyAuthMethod 'basic' || true) \
    && \
    ($GIT config --global http.sslverify false  || true) \
    && \
    ($GIT config --global https.sslverify false || true) \
    && \
    ($GIT config --global http.proxy $http_proxy || true) \
    && \
    ($GIT config --global https.proxy $https_proxy || true) \
    ; \
  fi \
  && \
  if [ ! -z "$GIT_WITH_OPENSSL" ]; then \
    echo 'building git from source, see ARG GIT_WITH_OPENSSL' \
    && \
    # Ubuntu's default git package is built with broken gnutls. Rebuild git with openssl.
    $APT update \
    #&& \
    #add-apt-repository ppa:git-core/ppa  \
    #apt-add-repository "deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu $(lsb_release -sc) main" \
    #&& \
    #apt-key add 1E9377A2BA9EF27F \
    #&& \
    #printf "deb-src http://ppa.launchpad.net/git-core/ppa/ubuntu ${CODE_NAME} main\n" >> /etc/apt/sources.list.d/git-core-ubuntu-ppa-bionic.list \
    && \
    $APT install -y --no-install-recommends \
       software-properties-common \
       fakeroot ca-certificates tar gzip zip \
       autoconf automake bzip2 file g++ gcc \
       #imagemagick libbz2-dev libc6-dev libcurl4-openssl-dev \
       #libglib2.0-dev libevent-dev \
       #libdb-dev  libffi-dev libgeoip-dev libjpeg-dev libkrb5-dev \
       #liblzma-dev libncurses-dev \
       #libmagickcore-dev libmagickwand-dev libmysqlclient-dev libpng-dev \
       libssl-dev libtool libxslt-dev \
       #libpq-dev libreadline-dev libsqlite3-dev libwebp-dev libxml2-dev \
       #libyaml-dev zlib1g-dev \
       make patch xz-utils unzip curl  \
    && \
    sed -i -- 's/#deb-src/deb-src/g' /etc/apt/sources.list \
    && \
    sed -i -- 's/# deb-src/deb-src/g' /etc/apt/sources.list \
    && \
    $APT update \
    && \
    $APT install -y gnutls-bin openssl \
    && \
    $APT install -y build-essential fakeroot dpkg-dev -y \
    #&& \
    #($APT remove -y git || true ) \
    && \
    $APT build-dep git -y \
    && \
    # git build deps
    $APT install -y libcurl4-openssl-dev liberror-perl git-man -y \
    && \
    mkdir source-git \
    && \
    cd source-git/ \
    && \
    $APT source git \
    && \
    cd git-2.*.*/ \
    && \
    sed -i -- 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/' ./debian/control \
    && \
    sed -i -- '/TEST\s*=\s*test/d' ./debian/rules \
    && \
    dpkg-buildpackage -rfakeroot -b -uc -us \
    && \
    dpkg -i ../git_*ubuntu*.deb \
    ; \
  fi \
  && \
  if [ "$GIT_CA_INFO" != "" ]; then \
    echo 'WARNING: GIT_CA_INFO CHANGED! SEE GIT_CA_INFO FLAG IN DOCKERFILE' \
    && \
    ($GIT config --global http.sslCAInfo $GIT_CA_INFO || true) \
    && \
    ($GIT config --global http.sslCAPath $GIT_CA_INFO || true) \
    ; \
  fi \
  && \
  if [ ! -z "$http_proxy" ]; then \
    echo 'WARNING: CONAN SSL CHECKS DISABLED! SEE http_proxy IN DOCKERFILE' \
    && \
    ($CONAN remote update conan-center https://conan.bintray.com False || true) \
    ; \
  else \
    ($CONAN remote update conan-center https://conan.bintray.com True || true) \
    ; \
  fi \
  && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && \
  ldconfig \
  && \
  update-ca-certificates --fresh \
  && \
  # need some git config to apply git patch
  ($GIT config --global user.email "$GIT_EMAIL" || true) \
  && \
  ($GIT config --global user.name "$GIT_USERNAME" || true) \
  && \
  export CC=gcc \
  && \
  export CXX=g++ \
  && \
  if [ ! -z "$http_proxy" ]; then \
    echo 'WARNING: GIT sslverify DISABLED! SEE http_proxy IN DOCKERFILE' \
    && \
    ($GIT config --global http.proxyAuthMethod 'basic' || true) \
    && \
    ($GIT config --global http.sslverify false || true) \
    && \
    ($GIT config --global https.sslverify false || true) \
    && \
    ($GIT config --global http.proxy $http_proxy || true) \
    && \
    ($GIT config --global https.proxy $https_proxy || true) \
    ; \
  fi \
  && \
  if [ ! -z "$CONAN_EXTRA_REPOS" ]; then \
    ($CONAN remote add $CONAN_EXTRA_REPOS || true) \
    ; \
  fi \
  && \
  if [ ! -z "$CONAN_EXTRA_REPOS_USER" ]; then \
    $CONAN $CONAN_EXTRA_REPOS_USER \
    ; \
  fi \
  && \
  # remove unused project copy after install
  # NOTE: must remove copied files
  cd $WDIR && rm -rf $PROJ_DIR
  #
  # NOTE: no need to clean apt in dev env
