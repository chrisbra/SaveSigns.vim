" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
doc/savesigns.txt	[[[1
69
*savesigns.txt*  Plugin to save Signs                - Vers 0.3  Feb 25, 2010

Author:  Christian Brabandt <cb@256bit.org>
							    *savesigns-copyright*
Copyright: (c) 2009 by Christian Brabandt 
	The VIM LICENSE applies to savesigns.vim, savesignsPlugin.vim
	and savesigns.txt (see |copyright|) except use savesigns instead
	of "Vim".
	NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.

{only available when compiled with the |+signs| feature}

==============================================================================
1. Contents						    *savesigns-contents*

1. Contents................................................|savesigns-contents|
2. Functionality...........................................|savesigns-plugin|
2.1   :SaveSigns...........................................|:SaveSigns|
3. History.................................................|savesigns-history|

==============================================================================
							    *savesigns-plugin*
2. Functionality

This plugin was written to allow you to save your |signs| easily. Signs can be
used to specific highlight certains rows in a buffer. This might be useful
when using a debugger or display a |mark|. Note however, that this works only
when the signs feature has been compiled into your vim.

If you have defined signs in your file, you might want to save these signs to
be able to reload these signs later on (e.g. with a |Session|). Therefore this
plugin defines the |:SaveSigns| command, which will store all defined signs in
a file in such a way that reloading that file will restore all defined signs.

When saving Signs, the plugin creates a Vim Script, that can be read in using
|:source| It will save Sign Definitions (see |:sign-define|), Sign placements
(see |:sign-place|) and the Sign hilighting (see |hl-SignColumn|).

Since signs are usually associated with a buffer or a file, sourcing this file
using |:source| will only restore those signs whose buffers are loaded in that
vim session. Note: All Signs that were defined before reloading this file will
be lost.

2.1 :SaveSigns							*:SaveSigns*

:SaveSigns		Store all currently defined signs in a temporary file.
			This file will be opened in a new split window and you
			can edit it further. Note: This file won't be saved.
			You need to explicitly save it.

:SaveSigns[!] {name}	Store all currently defined signs in a file called
			{name}. If this file exists, it won't be used a new
			temporary file will be created. Use ! to force storing
			the info in that file. This will however erase the
			file {name}. So use with caution.


==============================================================================
							    *savesigns-history*
3. savesigns History

0.3     - Enabled GLVS (see :h GLVS)
0.2     - Uploaded to http://www.vim.org/
        - Created autoload script
        - Created documentation
        - added some more error handling.
0.1     - First initial version
==============================================================================
vim:tw=78:ts=8:ft=help
autoload/savesigns.vim	[[[1
139
" savesigns.vim - Vim global plugin for saving Signs
" -------------------------------------------------------------
" Last Change: 2010, Feb 25
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Version:     0.3
" Copyright:   (c) 2009 by Christian Brabandt
"              The VIM LICENSE applies to histwin.vim 
"              (see |copyright|) except use "savesigns.vim" 
"              instead of "Vim".
"              No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
"
" TODO: - write documentation

" Init:
let s:cpo= &cpo
set cpo&vim

fu! <sid>Output(mess, hi)"{{{
    exe "echohl" a:hi
    echomsg a:mess
    sleep 2
    echohl "Normal"
endfu"}}}

fu! savesigns#ParseSignsOutput(...)
    if !has("signs")
       call <sid>Output("Aborting, because your vim does not support Signs", "ErrorMsg")
       return
    endif

    let s:signs=[]
    let s:signdict={}

    " Get Highlighting of SignColumn
    redir => a
	sil hi SignColumn
    redir end

    let hi=split(a, '\n')[0]
    let hi=substitute(hi, "^", "hi! ", "")
    let hi=substitute(hi, '\s\+xxx\s\+', " ", "")
    let s:signs = [ '" Highlighting Definition of Signs',
		  \ hi,
		  \  '']


    " Get Definition of Signs
    redir => a
	sil sign list
    redir end

    call add(s:signs, '" Define Signs')
    let s:signs += split(a, '\n')
    call map(s:signs, 'substitute(v:val, "^sign", "& define", "")')
    let s:signs += [ '', '" Define Placement of Signs' ]


    " Get placement of signs
    redir => a
	sil sign place
    redir end

    let list=split(a, '\n')[1:]
    call filter(list, "!empty(v:val)")
    let fname=""
    let pat='^Signs for \zs.*\ze:'
    for val in list
	if match(val, pat) >= 0
	    let fname=fnamemodify(matchstr(val, pat), ':p')
	    let s:signdict[fname]=[]
	else
	    let place=split(val, '\s\+')
            if place[2] =~ '\[Deleted\]'
		continue
	    endif
	    call add(s:signdict[fname], "\tsign place " . matchstr(place[1],'id=\zs.*')  . " " . place[0] . " " . place[2] . " file=".fname )
	endif
    endfor
    for file in keys(s:signdict)
	call insert(s:signdict[file], "if bufexists('" . file . "')")
	call add(s:signdict[file], "endif")
    endfor
    call <sid>CreateSignFiles(empty(a:1) ? '' : a:1, empty(a:2) ? 0 : 1)
endfu

fun! <sid>CreateSignFiles(fname, force)
    if !empty(s:signs) && !empty(keys(s:signdict))
	if !empty(a:fname) && !isdirectory(a:fname) && (a:force || !filereadable(a:fname))
	    let filename=a:fname
	else
	    if filereadable(a:fname)
		call <sid>Output("File " . a:fname . " exists! Creating new file. Use '!' to override.", "WarningMsg")
	    endif
	    let filename=tempname()
	endif

	if bufloaded(filename)
	    exe bufwinnr(filename) . "wincmd w"
	else
	    exe ":sp" filename
	endif
	%d

	call append('.', [ '" Source this file, to reload all signs',
		    \'" Signs that are defined for files which are currently not loaded',
		    \'" will not be restored!',
		    \'',
		    \'" Check for +sign Feature',
		    \'if !has("signs") | finish | endif ',
		    \'',
		    \'" Remove all previously placed signs',
		    \'sign unplace *',
		    \'',
		    \'" Undefine all previously defined signs' ,
		    \'redir => s:a | exe "sil sign list" | redir end',
		    \'let s:signlist=split(s:a, "\n")',
		    \"call map(s:signlist, '\"sign undefine \" . split(v:val, ''\\s\\+'')[1]')",
		    \'for sign in s:signlist | exe sign | endfor ', 
		    \'unlet s:signlist s:a',
		    \''])
	$
	call append('.',s:signs)
	for file in keys(s:signdict)
	    call append('$', s:signdict[file])
	endfor
	setf vim
	1
	d
	"setl nomodified
    else
	    call <sid>Output("No Signs Defined. Nothing to do", "WarningMsg")
    endif
endfun

" Restore:"{{{
let &cpo=s:cpo
unlet s:cpo"}}}
" vim: ts=4 sts=4 fdm=marker com+=l\:\" spell spelllang=en
plugin/savesignsPlugin.vim	[[[1
41
" savesigns.vim - Vim global plugin for Saving Signs
" -------------------------------------------------------------
" Last Change: 2010, Feb 25
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Version:     0.3
" Copyright:   (c) 2010 by Christian Brabandt
"              The VIM LICENSE applies to histwin.vim 
"              (see |copyright|) except use "savesigns.vim" 
"              instead of "Vim".
"              No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
"
" GetLatestVimScripts: 2992 2 :AutoInstall: savesigns.vim
" TODO: - write documentation

" Init:"{{{
if exists("g:loaded_savesigns") || &cp || !has("signs")
  finish
endif

let g:loaded_savesigns   = 0.3
let s:cpo                = &cpo
set cpo&vim"}}}

" User_Command:"{{{
if exists(":SaveSigns") != 2
	com! -nargs=? -bang -complete=file SaveSigns 
	\:call savesigns#ParseSignsOutput(<q-args>, "<bang>")
else
	echoerr ":SaveSigns is already defined. May be by another Plugin?"
endif"}}}

" Restore:"{{{
let &cpo=s:cpo
unlet s:cpo"}}}

" ChangeLog:
" 0.3     - Enable GLVS (see :h GLVS)
" 0.2	  - Make autoload plugin
" 0.1     - First working version
" vim: ts=4 sts=4 fdm=marker com+=l\:\" spell spelllang=en fdm=marker
