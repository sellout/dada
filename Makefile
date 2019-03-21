
lint:
	./scripts/find-dhall-files.sh -type f -exec dhall lint --inplace {} \;

compile:
	./scripts/compile.sh

freeze:
	./scripts/freeze.sh

doc:
	mkdir -p docs
	./scripts/doc.sh >docs/index.html
