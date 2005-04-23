all: html documentation.pdf

html: documentation.xml
	mkdir -p output
	xsltproc --stringparam base.dir output/ --stringparam chunk.fast yes --stringparam chunker.output.encoding UTF-8 --stringparam chunker.output.indent yes --stringparam use.id.as.filename yes --stringparam html.stylesheet ../style.css /sw/share/xml/xsl/docbook-xsl/xhtml/chunk.xsl documentation.xml

documentation.pdf: documentation.fo
	fop -fo documentation.fo -pdf documentation.pdf

documentation.fo: documentation.xml
	xsltproc --output documentation.fo --stringparam fop.extensions 1 /sw/share/xml/xsl/docbook-xsl/fo/docbook.xsl documentation.xml

clean:
	rm -rf output
