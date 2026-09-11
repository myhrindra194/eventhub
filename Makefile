# EventHub developer shortcuts. Requires GNU make (Git Bash / WSL on Windows).
DEVICE ?=
FLAVOR ?= dev
DART_DEFINES = --dart-define=FLAVOR=$(FLAVOR)

.PHONY: help setup gen watch analyze format test test-cov test-rules rules-setup run run-mock run-emu build-apk clean emulators firebase-deploy

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

run-mock: ## Run with the in-memory backend (no Firebase project needed)
	flutter run $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES) --dart-define=MOCK=true

run-emu: ## Run against the local Firebase emulator suite
	flutter run $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES) --dart-define=USE_EMULATORS=true

build-apk: ## Release APK for FLAVOR
	flutter build apk --release $(DART_DEFINES)

emulators: ## Start Firebase emulators (auth, firestore, storage)
	firebase emulators:start

firebase-deploy: ## Deploy Firestore/Storage rules and indexes
	firebase deploy --only firestore:rules,firestore:indexes,storage

clean: ## Clean build artefacts
	flutter clean
	rm -rf .dart_tool/build
