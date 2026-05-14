.PHONY: build
build:
	dart run build_runner build --delete-conflicting-outputs
	dart run pigeon --input pigeon/layrz_ble.dart

.PHONY: pigeon
pigeon:
	dart run pigeon --input pigeon/layrz_ble.dart

.PHONY: lint
lint:
	dart fix --dry-run

.PHONY: test
test:
	flutter test

.PHONY: clean
clean:
	flutter clean
	cd example
	flutter clean
	cd ..
	flutter pub get

.PHONY: run
run:
	$(MAKE) -C example run
