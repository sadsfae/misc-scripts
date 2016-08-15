NAME = supybot-excuses
VERSION = 0.1

.PHONY: dist

dist:
	mkdir -p dist
	mkdir -p $(NAME)-$(VERSION)
	cp *.py *.txt $(NAME)-$(VERSION)
	tar cj $(NAME)-$(VERSION) > dist/$(NAME)-$(VERSION).tar.bz2
	rm -rf $(NAME)-$(VERSION)

clean:
	rm -rf dist
