.PHONY: test analyze coverage coverage-html clean-coverage

test:
	dart test

analyze:
	dart analyze

coverage:
	dart test --coverage=coverage/raw
	dart run coverage:format_coverage \
		--lcov \
		--in=coverage/raw \
		--out=coverage/lcov.info \
		--report-on=bin/

coverage-html: coverage
	@which genhtml > /dev/null || (echo "genhtml not found — install lcov: brew install lcov" && exit 1)
	genhtml coverage/lcov.info -o coverage/html
	@echo "Coverage report: coverage/html/index.html"

clean-coverage:
	rm -rf coverage/raw coverage/html coverage/lcov.info
