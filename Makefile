
SRC_FILES := $(sort $(filter-out README.md,$(wildcard *.md)))

OUTPUT_DIR := build
STYLE_CSS := style.css
METADATA := metadata.json
# Slugify via pandoc's own heading-identifier generation (ASCII-transliterated).
BOOK_TITLE := $(shell jq -r '"\# " + (.filename // .title // "")' $(METADATA) | \
	pandoc -f markdown-smart+gfm_auto_identifiers+ascii_identifiers -t json | \
	jq -r '.blocks[0].c[1][0] // "" | gsub("[^a-z0-9]+"; "-") | gsub("^-|-$$"; "") | sub("^section$$"; "")')
BOOK_TITLE := $(or $(BOOK_TITLE),book)

OUTPUT_EPUB := $(OUTPUT_DIR)/$(BOOK_TITLE).epub
OUTPUT_HTML := $(OUTPUT_DIR)/$(BOOK_TITLE).html
OUTPUT_MD   := $(OUTPUT_DIR)/$(BOOK_TITLE).md

.PHONY: all clean html epub md

all:  html epub
html: $(OUTPUT_HTML)
epub: $(OUTPUT_EPUB)
md: $(OUTPUT_MD)

clean:
	rm -rf $(OUTPUT_DIR)

HTML_FLAGS := --to html5 --standalone --embed-resources --section-divs
EPUB_FLAGS := --to epub3 --toc --split-level 2
GLOBAL_FLAGS := --metadata-file $(METADATA) --css $(STYLE_CSS)

$(OUTPUT_EPUB): $(METADATA) $(SRC_FILES) $(STYLE_CSS) Makefile
	@test "$(SRC_FILES)"
	@mkdir -p $(dir $@)
	pandoc $(EPUB_FLAGS) $(GLOBAL_FLAGS) $(SRC_FILES) --output $@

$(OUTPUT_HTML): $(METADATA) $(SRC_FILES) $(STYLE_CSS) Makefile
	@test "$(SRC_FILES)"
	@mkdir -p $(dir $@)
	pandoc $(HTML_FLAGS) $(GLOBAL_FLAGS) $(SRC_FILES) --output $@

$(OUTPUT_MD): $(METADATA) $(SRC_FILES) Makefile
	@test "$(SRC_FILES)"
	@mkdir -p $(dir $@)
	jq -j '[ \
		(.title | strings | select(. != "") | "# \(.)"), \
		(.subtitle | strings | select(. != "") | "*\(.)*"), \
		(.author | if type == "array" then join(", ") else . end | strings | select(. != "")) \
		] | map(. + "\n\n") | add // ""' $(METADATA) > $@
	for x in $(SRC_FILES); do cat $$x; printf '\n\n'; done >> $@

