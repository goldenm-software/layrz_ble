.PHONY: all test build lint clean

build:
	dart run build_runner build --delete-conflicting-outputs

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