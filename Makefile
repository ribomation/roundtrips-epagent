
SRC_DIR     = ./src/main
TST_DIR     = ./src/test
CLW_DIR     = ./src/test/apm-clw

BLD_DIR     = ./build
DST_DIR     = $(BLD_DIR)/dist

NAME        = roundtrips
VERSION     = 2.1


help:
	@echo "usage: make {target}"
	@echo "targets:"
	@echo "  build   - builds the TAR archive"
	@echo "  clean   - removes the build/ dir"
	@echo "  test    - runs the unit tests"
	@echo "  testv   - runs the unit tests in verbose mode, showing all tests"
	@echo "  metrics - retrieves all round-trip metric names"

clean:
	rm -rf $(BLD_DIR)

build: clean
	mkdir -p $(DST_DIR)/lib
	cp $(SRC_DIR)/script/*.sh           $(DST_DIR)
	cp $(SRC_DIR)/conf/parameters.conf  $(DST_DIR)
	cp $(SRC_DIR)/conf/agents.csv       $(DST_DIR)
	cp $(SRC_DIR)/conf/agent.properties $(DST_DIR)/lib
	cp $(SRC_DIR)/jar/EPAgent.jar       $(DST_DIR)/lib
	cp $(SRC_DIR)/perl/*.pm             $(DST_DIR)/lib
	cp $(SRC_DIR)/perl/*.pl             $(DST_DIR)/lib
	tar cvfz $(BLD_DIR)/$(NAME)-$(VERSION).tar.gz -C $(DST_DIR) .

test:
	prove $(TST_DIR)/perl/*.t

testv:
	prove --verbose $(TST_DIR)/perl/*.t

metrics:
	( cd $(CLW_DIR); perl ./get-metric-names.pl )

