REBAR = $(realpath ./rebar)

suite=$(if $(SUITE), suite=$(SUITE), )

.PHONY:	all deps check test clean

all: compile

compile: deps
	$(REBAR) compile

deps:
	$(REBAR) get-deps

docs:
	$(REBAR) doc

check:
	$(REBAR) check-plt
	$(REBAR) dialyze

test:
	$(REBAR) eunit $(suite) apps=erlavro

conf_clean:
	@:

clean:
	$(REBAR) clean
	$(RM) doc/*

# eof
