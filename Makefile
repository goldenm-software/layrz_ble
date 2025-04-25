.PHONY: all test build lint clean pigeon

build:
	dart run build_runner build --delete-conflicting-outputs
	dart run pigeon --input pigeon/layrz_ble.dart

pigeon:
	dart run pigeon --input pigeon/layrz_ble.dart

lint:
	dart fix --dry-run

test:
	flutter test

clean:
	flutter clean
	cd example
	flutter clean
	cd ..
	flutter pub get