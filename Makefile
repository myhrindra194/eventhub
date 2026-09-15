# EventHub developer shortcuts. Requires GNU make (Git Bash / WSL on Windows).
#
# Backend: Firebase Auth + Cloud Firestore on the Spark plan. There is no
# server code to deploy: the security rules (firebase/firestore.rules) and the
# indexes are the whole backend, plus the static Hosting site.

DEVICE ?=
FLAVOR ?= dev
# Public dart-defines of a flavor (emulator switch, Google client id, VAPID
# key). env/dev.json is versioned; template: env/example.json.
ENV_FILE ?= env/$(FLAVOR).json
ENTRYPOINT ?= lib/main_$(FLAVOR).dart
DART_DEFINES = --dart-define=FLAVOR=$(FLAVOR) $(if $(wildcard $(ENV_FILE)),--dart-define-from-file=$(ENV_FILE),)

# Cloud project (see .firebaserc) and the throwaway project of the rules suite.
PROJECT ?= eventhub-d411f
TEST_PROJECT = demo-eventhub
# `localhost` on desktop, web and the iOS simulator; `10.0.2.2` from the
# Android emulator; the computer's LAN address from a physical phone.
EMULATOR_HOST ?= localhost

# The Firebase CLI is pinned in firebase/tests/package-lock.json, so every
# machine and CI run the same version (`make rules-setup` installs it).
FIREBASE = npx --prefix firebase/tests firebase

.PHONY: help setup gen watch analyze format test test-cov \
	run run-web run-emulator build-apk build-web build-windows \
	rules-setup emulators rules-test deploy-rules hosting-deploy deploy grant-admin clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# ------------------------------------------------------------------ app ---

setup: ## Install deps and generate code
	flutter pub get
	$(MAKE) gen

gen: ## Run code generation (freezed, riverpod, json)
	dart run build_runner build --delete-conflicting-outputs

watch: ## Code generation in watch mode
	dart run build_runner watch --delete-conflicting-outputs

analyze: ## Static analysis
	flutter analyze --no-pub

format: ## Format sources
	dart format lib test

test: ## Unit + widget tests
	flutter test

test-cov: ## Tests with coverage report
	flutter test --coverage

run: ## Run on $(DEVICE) against the cloud project (FLAVOR, env/<flavor>.json)
	flutter run -t $(ENTRYPOINT) $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES)

run-web: ## Run in Chrome against the cloud project
	flutter run -d chrome -t $(ENTRYPOINT) $(DART_DEFINES)

run-emulator: ## Run on $(DEVICE) against local emulators (EMULATOR_HOST=10.0.2.2 for an Android emulator)
	flutter run -t $(ENTRYPOINT) $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES) \
		--dart-define=USE_FIREBASE_EMULATOR=true --dart-define=FIREBASE_EMULATOR_HOST=$(EMULATOR_HOST)

build-apk: ## Release APK for FLAVOR (env/<flavor>.json)
	flutter build apk --release -t $(ENTRYPOINT) $(DART_DEFINES)

build-web: ## Release web build for FLAVOR (build/web)
	flutter build web --release -t $(ENTRYPOINT) $(DART_DEFINES)

build-windows: ## Release Windows build for FLAVOR (run on Windows)
	flutter build windows --release -t $(ENTRYPOINT) $(DART_DEFINES)

# ------------------------------------------------------------- backend ---

rules-setup: ## Install the rules suite and the pinned Firebase CLI (Node 20+, Java 21)
	npm ci --prefix firebase/tests

emulators: ## Auth + Firestore emulators with the UI on :4000 (data kept in .emulator-data/)
	$(FIREBASE) --project $(PROJECT) emulators:start --only auth,firestore \
		--import=.emulator-data --export-on-exit=.emulator-data

rules-test: ## Security-rules suite against the Firestore emulator (no credentials)
	$(FIREBASE) --project $(TEST_PROJECT) emulators:exec --only firestore "npm --prefix firebase/tests test"

deploy-rules: rules-test ## Deploy rules, composite indexes and the TTL policy (tests first)
	$(FIREBASE) --project $(PROJECT) deploy --only firestore:rules,firestore:indexes

hosting-deploy: ## Deploy the public site (shared event links, App Links)
	$(FIREBASE) --project $(PROJECT) deploy --only hosting

deploy: deploy-rules hosting-deploy ## Rules, indexes and Hosting

grant-admin: ## How to grant an administrator: UID=<uid> EMAIL=<email>
	@echo "Firebase console → Firestore Database → Data → Start collection:"
	@echo "  collection: admins   document id: $(UID)"
	@echo "  fields: email (string) = $(EMAIL), grantedAt (timestamp) = now"
	@echo "The uid is in Authentication → Users. To revoke, delete the document."

clean: ## Clean build artefacts
	flutter clean
	rm -rf .dart_tool/build
