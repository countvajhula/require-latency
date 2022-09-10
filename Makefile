# Adapted from: http://www.greghendershott.com/2017/04/racket-makefiles.html
PACKAGE-NAME=require-latency

DEPS-FLAGS=--check-pkg-deps --unused-pkg-deps

help:
	@echo "build - Compile libraries"
	@echo "build-docs - Build docs"
	@echo "check-deps - Check dependencies"
	@echo "build-all - Compile libraries, build docs, and check dependencies"
	@echo "clean - Remove all build artifacts"
	@echo "install - Install package along with dependencies"
	@echo "remove - Remove package"
	@echo "docs - View docs in a browser"

# Primarily for use by CI.
# Installs dependencies as well as linking this as a package.
install:
	raco pkg install --deps search-auto --link $(PWD)/$(PACKAGE-NAME)

remove:
	raco pkg remove $(PACKAGE-NAME)

# Add the former as a make target if warranted, as it seems to
# be necessary in some cases (e.g. linking to third party lib docs)

# Primarily for day-to-day dev.
# Build libraries from source.
build:
	raco setup --no-docs --tidy --pkgs $(PACKAGE-NAME)

# Primarily for day-to-day dev.
# Build docs (if any).
build-docs:
	raco setup --no-launcher --no-foreign-libs --no-info-domain --no-pkg-deps \
	--no-install --no-post-install --tidy --pkgs $(PACKAGE-NAME)

# Primarily for day-to-day dev.
# Build libraries from source, build docs (if any), and check dependencies.
build-all:
	raco setup --tidy $(DEPS-FLAGS) --pkgs $(PACKAGE-NAME)

# Primarily for use by CI, after make install -- since that already
# does the equivalent of make setup, this tries to do as little as
# possible except checking deps.
check-deps:
	raco setup --no-docs $(DEPS-FLAGS) --pkgs $(PACKAGE-NAME)

# Note: Each collection's info.rkt can say what to clean, for example
# (define clean '("compiled" "doc" "doc/<collect>")) to clean
# generated docs, too.
clean:
	raco setup --fast-clean --pkgs $(PACKAGE-NAME)

docs:
	raco docs $(PACKAGE-NAME)

.PHONY:	help install remove build build-docs build-all check-deps clean test test-logic test-equivalence test-order test-function test-type test-composition errortrace-logic errortrace-equivalence errortrace-order errortrace-function errortrace-type errortrace-composition test-with-errortrace errortrace docs profile-logic profile-equivalence profile-order profile-function profile-type profile-composition profile cover coverage-check coverage-report cover-coveralls
