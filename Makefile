# EventHub developer shortcuts. Requires GNU make (Git Bash / WSL on Windows).
DEVICE ?=
FLAVOR ?= dev
# Supabase URL, anon key and the other build-time keys of a flavor live in
# env/<flavor>.json (git-ignored). Template: env/example.json.
ENV_FILE ?= env/$(FLAVOR).json
DART_DEFINES = --dart-define=FLAVOR=$(FLAVOR) $(if $(wildcard $(ENV_FILE)),--dart-define-from-file=$(ENV_FILE),)
SUPABASE = npx --yes supabase

.PHONY: help setup gen watch analyze format test test-cov db-setup test-db functions-check \
	supabase-login supabase-link db-push functions-deploy secrets-push config-push \
	hosting-config hosting-deploy deploy grant-admin run build-apk clean

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

run: ## Run on $(DEVICE) with FLAVOR=$(FLAVOR) and env/$(FLAVOR).json
	flutter run $(if $(DEVICE),-d $(DEVICE),) $(DART_DEFINES)

build-apk: ## Release APK for FLAVOR (env/$(FLAVOR).json)
	flutter build apk --release $(DART_DEFINES)

# ------------------------------------------------------------- backend ---

db-setup: ## Install the database test suite (PGlite, no Docker)
	npm --prefix supabase/tests ci

test-db: ## Migrations, RLS, RPCs, triggers, payments, jobs — on Postgres 17 in WebAssembly
	npm --prefix supabase/tests test

functions-check: ## Type-check every Edge Function (Deno)
	cd supabase/functions && npx --yes deno check */index.ts

supabase-login: ## Authenticate the Supabase CLI (opens the browser)
	$(SUPABASE) login

supabase-link: ## Link this folder to the cloud project: PROJECT_REF=<ref>
	$(SUPABASE) link --project-ref $(PROJECT_REF)

db-push: test-db ## Apply pending migrations to the linked project (tests first)
	$(SUPABASE) db push

functions-deploy: functions-check ## Deploy every Edge Function
	$(SUPABASE) functions deploy

secrets-push: ## Upload supabase/functions/.env as Edge Function secrets
	$(SUPABASE) secrets set --env-file supabase/functions/.env

config-push: ## Apply supabase/config.toml (Auth: redirects, confirmation, Google) to the project
	$(SUPABASE) config push

hosting-config: ## Write hosting/public/eventhub-config.js from env/prod.json
	node -e "const e=require('./env/prod.json');require('fs').writeFileSync('hosting/public/eventhub-config.js','window.EVENTHUB = '+JSON.stringify({functionsUrl:e.SUPABASE_URL.replace(/\/$$/,'')+'/functions/v1'},null,2)+';\n')"

hosting-deploy: hosting-config ## Deploy the public site (shared links, Checkout return, App Links)
	firebase deploy --only hosting

deploy: db-push functions-deploy hosting-deploy ## Migrations, Edge Functions and Hosting

grant-admin: ## How to grant the first administrator: EMAIL=<email>
	@echo "Supabase → SQL Editor, then run:"
	@echo "  select private.grant_admin('$(EMAIL)');"
	@echo "(to revoke: select private.grant_admin('$(EMAIL)', false);)"

clean: ## Clean build artefacts
	flutter clean
	rm -rf .dart_tool/build
