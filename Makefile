pull_deps:
	mix local.hex --force
	mix local.rebar --force
	mix deps.get

linter:
	mix format --check-formatted
	# mix credo

unit_test:
	mix coveralls.json

docs_report:
	mix inch.report

push_docs_report:
	bash <(curl -s https://codecov.io/bash)