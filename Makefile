# EventHub developer shortcuts. Requires GNU make (Git Bash / WSL on Windows).
DEVICE ?=
FLAVOR ?= dev
DART_DEFINES = --dart-define=FLAVOR=$(FLAVOR)

.PHONY: help setup gen watch analyze format test test-cov test-rules rules-setup run run-emu build-apk clean emulators firebase-deploy functions-setup functions-build test-functions deploy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

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

rules-setup: ## Install the Node deps of the security-rules test suite
	npm --prefix firebase/tests install

test-rules: ## Firestore + Storage security rules, against the emulators (needs Java)
	firebase/tests/node_modules/.bin/firebase --project demo-eventhub emulators:exec --only firestore,storage "npm --prefix firebase/tests test"

run: ## Run on $(DEVICE) with FLAVOR=$(FLAVOR)
	flutter run $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES)

run-emu: ## Run against the local Firebase emulator suite
	flutter run $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES) --dart-define=USE_EMULATORS=true

build-apk: ## Release APK for FLAVOR
	flutter build apk --release $(DART_DEFINES)

emulators: ## Start Firebase emulators (auth, firestore, storage)
	firebase emulators:start

firebase-deploy: ## Deploy Firestore/Storage rules and indexes
	firebase deploy --only firestore:rules,firestore:indexes,storage

functions-setup: ## Install the Cloud Functions dependencies
	npm --prefix functions install

functions-build: ## Compile the Cloud Functions (TypeScript)
	npm --prefix functions run build

test-functions: functions-build ## Cloud Functions integration tests, against the emulators (needs Java)
	firebase/tests/node_modules/.bin/firebase --project demo-eventhub emulators:exec --only auth,firestore,functions,storage "npm --prefix functions test"

deploy: functions-build ## Deploy rules, indexes, Storage rules and Cloud Functions (Blaze plan)
	firebase deploy --only firestore,storage,functions

clean: ## Clean build artefacts
	flutter clean
	rm -rf .dart_tool/build
