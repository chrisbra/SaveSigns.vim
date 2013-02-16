SCRIPT=plugin/savesignsPlugin.vim autoload/savesigns.vim
DOC=doc/savesigns.txt
PLUGIN=savesigns

.PHONY : $(PLUGIN).vmb

all: $(PLUGIN) $(PLUGIN).vmb

clean:
	rm -rf *.vmb */*.orig *.~* .VimballRecord doc/tags

dist-clean: clean

vimball: $(PLUGIN).vmb

install:
	vim -N -c':so %' -c':q!' ${PLUGIN}.vmb

uninstall:
	vim -u NONE -N -c':RmVimball ${PLUGIN}.vmb'

undo:
	for i in */*.orig; do mv -f "$$i" "$${i%.*}"; done

savesigns.vmb:
	vim -N -c 'ru! vimballPlugin.vim' -c ':let g:vimball_home=getcwd()'  -c ':call append("0", ["plugin/savesignsPlugin.vim", "autoload/savesigns.vim", "doc/savesigns.txt"])' -c '$$d' -c ':%MkVimball ${PLUGIN}' -c':q!'

savesigns:
	rm -f ${PLUGIN}.vmb
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d)*/sprintf(".%d", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/^let g:loaded_undo_browse/) {s/\.(\d)*/sprintf(".%d", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/GetLatestVimScripts:/) {s/(\d+)\s+:AutoInstall:/sprintf("%d :AutoInstall:", 1+$$1)/e}' ${SCRIPT}
	perl -i -pne 'if (/Last Change:/) {s/(:\s+).*$$/sprintf(": %s", `date -R`)/e}' ${SCRIPT}
	perl -i.orig -pne 'if (/Version:/) {s/\.(\d)+.*\n/sprintf(".%d %s", 1+$$1, `date -R`)/e}' ${DOC}
