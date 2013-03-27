# TESTS = $(shell find test -name "*.coffee")

test:
	npm test

coverage:
	cake build
	jscoverage --no-highlight lib lib-cov
	FORM_COV=1 mocha -r should --compilers coffee:coffee-script -R html-cov > coverage.html
	rm -rf lib-cov

.PHONY: test