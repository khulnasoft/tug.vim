if exists('g:loaded_tug_vim')
  finish
endif
let g:loaded_tug_vim = 1

let s:cpo_save = &cpo
set cpo&vim
let s:is_win = has('win32') || has('win64')

function! s:conf(name, default)
  let conf = get(g:, 'tug_vim', {})
  let val = get(conf, a:name, get(g:, 'tug_' . a:name, a:default))
  return val
endfunction

function! s:defs(commands)
  let prefix = s:conf('command_prefix', '')
  if prefix =~# '^[^A-Z]'
    echoerr 'g:tug_command_prefix must start with an uppercase letter'
    return
  endif
  for command in a:commands
    let name = ':'.prefix.matchstr(command, '\C[A-Z]\S\+')
    if 2 != exists(name)
      execute substitute(command, '\ze\C[A-Z]', prefix, '')
    endif
  endfor
endfunction

call s:defs([
\'command!      -bang -nargs=? -complete=dir Files              call tug#vim#files(<q-args>, tug#vim#with_preview(), <bang>0)',
\'command!      -bang -nargs=? GitFiles                         call tug#vim#gitfiles(<q-args>, tug#vim#with_preview(<q-args> == "?" ? { "placeholder": "" } : {}), <bang>0)',
\'command!      -bang -nargs=? GFiles                           call tug#vim#gitfiles(<q-args>, tug#vim#with_preview(<q-args> == "?" ? { "placeholder": "" } : {}), <bang>0)',
\'command! -bar -bang -nargs=? -complete=buffer Buffers         call tug#vim#buffers(<q-args>, tug#vim#with_preview({ "placeholder": "{1}" }), <bang>0)',
\'command!      -bang -nargs=* Lines                            call tug#vim#lines(<q-args>, <bang>0)',
\'command!      -bang -nargs=* BLines                           call tug#vim#buffer_lines(<q-args>, <bang>0)',
\'command! -bar -bang Colors                                    call tug#vim#colors(<bang>0)',
\'command!      -bang -nargs=+ -complete=dir Locate             call tug#vim#locate(<q-args>, tug#vim#with_preview(), <bang>0)',
\'command!      -bang -nargs=* Ag                               call tug#vim#ag(<q-args>, tug#vim#with_preview(), <bang>0)',
\'command!      -bang -nargs=* Rg                               call tug#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -- ".tug#shellescape(<q-args>), tug#vim#with_preview(), <bang>0)',
\'command!      -bang -nargs=* RG                               call tug#vim#grep2("rg --column --line-number --no-heading --color=always --smart-case -- ", <q-args>, tug#vim#with_preview(), <bang>0)',
\'command!      -bang -nargs=* Tags                             call tug#vim#tags(<q-args>, tug#vim#with_preview({ "placeholder": "--tag {2}:{-1}:{3..}" }), <bang>0)',
\'command!      -bang -nargs=* BTags                            call tug#vim#buffer_tags(<q-args>, tug#vim#with_preview({ "placeholder": "{2}:{3..}" }), <bang>0)',
\'command! -bar -bang Snippets                                  call tug#vim#snippets(<bang>0)',
\'command! -bar -bang Commands                                  call tug#vim#commands(<bang>0)',
\'command! -bar -bang Jumps                                     call tug#vim#jumps(tug#vim#with_preview({ "placeholder": "{2..4}"}), <bang>0)',
\'command! -bar -bang Marks                                     call tug#vim#marks(<bang>0)',
\'command! -bar -bang Changes                                   call tug#vim#changes(<bang>0)',
\'command! -bar -bang Helptags                                  call tug#vim#helptags(tug#vim#with_preview({ "placeholder": "--tag {2}:{3}:{4}" }), <bang>0)',
\'command! -bar -bang Windows                                   call tug#vim#windows(tug#vim#with_preview({ "placeholder": "{2}" }), <bang>0)',
\'command! -bar -bang -nargs=* -range=% -complete=file Commits  let b:tug_winview = winsaveview() | <line1>,<line2>call tug#vim#commits(<q-args>, tug#vim#with_preview({ "placeholder": "" }), <bang>0)',
\'command! -bar -bang -nargs=* -range=% BCommits                let b:tug_winview = winsaveview() | <line1>,<line2>call tug#vim#buffer_commits(<q-args>, tug#vim#with_preview({ "placeholder": "" }), <bang>0)',
\'command! -bar -bang Maps                                      call tug#vim#maps("n", <bang>0)',
\'command! -bar -bang Filetypes                                 call tug#vim#filetypes(<bang>0)',
\'command!      -bang -nargs=* History                          call s:history(<q-args>, tug#vim#with_preview(), <bang>0)'])

function! s:history(arg, extra, bang)
  let bang = a:bang || a:arg[len(a:arg)-1] == '!'
  if a:arg[0] == ':'
    call tug#vim#command_history(bang)
  elseif a:arg[0] == '/'
    call tug#vim#search_history(bang)
  else
    call tug#vim#history(a:extra, bang)
  endif
endfunction

function! tug#complete(...)
  return call('tug#vim#complete', a:000)
endfunction

if (has('nvim') || has('terminal') && has('patch-8.0.995')) && (s:conf('statusline', 1) || s:conf('nvim_statusline', 1))
  function! s:tug_restore_colors()
    if exists('#User#TugStatusLine')
      doautocmd User TugStatusLine
    else
      if $TERM !~ "256color"
        highlight default tug1 ctermfg=1 ctermbg=8 guifg=#E12672 guibg=#565656
        highlight default tug2 ctermfg=2 ctermbg=8 guifg=#BCDDBD guibg=#565656
        highlight default tug3 ctermfg=7 ctermbg=8 guifg=#D9D9D9 guibg=#565656
      else
        highlight default tug1 ctermfg=161 ctermbg=238 guifg=#E12672 guibg=#565656
        highlight default tug2 ctermfg=151 ctermbg=238 guifg=#BCDDBD guibg=#565656
        highlight default tug3 ctermfg=252 ctermbg=238 guifg=#D9D9D9 guibg=#565656
      endif
      setlocal statusline=%#tug1#\ >\ %#tug2#fz%#tug3#f
    endif
  endfunction

  function! s:tug_vim_term()
    if get(w:, 'airline_active', 0)
      let w:airline_disabled = 1
      autocmd BufWinLeave <buffer> let w:airline_disabled = 0
    endif
    autocmd WinEnter,ColorScheme <buffer> call s:tug_restore_colors()

    setlocal nospell
    call s:tug_restore_colors()
  endfunction

  augroup _tug_statusline
    autocmd!
    autocmd FileType tug call s:tug_vim_term()
  augroup END
endif

if !exists('g:tug#vim#buffers')
  let g:tug#vim#buffers = {}
endif

augroup tug_buffers
  autocmd!
  if exists('*reltimefloat')
    autocmd BufWinEnter,WinEnter * let g:tug#vim#buffers[bufnr('')] = reltimefloat(reltime())
  else
    autocmd BufWinEnter,WinEnter * let g:tug#vim#buffers[bufnr('')] = localtime()
  endif
  autocmd BufDelete * silent! call remove(g:tug#vim#buffers, expand('<abuf>'))
augroup END

inoremap <expr> <plug>(tug-complete-word)        tug#vim#complete#word()
if s:is_win
  inoremap <expr> <plug>(tug-complete-path)      tug#vim#complete#path('dir /s/b')
  inoremap <expr> <plug>(tug-complete-file)      tug#vim#complete#path('dir /s/b/a:-d')
else
  inoremap <expr> <plug>(tug-complete-path)      tug#vim#complete#path("find . -path '*/\.*' -prune -o -print \| sed '1d;s:^..::'")
  inoremap <expr> <plug>(tug-complete-file)      tug#vim#complete#path("find . -path '*/\.*' -prune -o -type f -print -o -type l -print \| sed 's:^..::'")
endif
inoremap <expr> <plug>(tug-complete-file-ag)     tug#vim#complete#path('ag -l -g ""')
inoremap <expr> <plug>(tug-complete-line)        tug#vim#complete#line()
inoremap <expr> <plug>(tug-complete-buffer-line) tug#vim#complete#buffer_line()

nnoremap <silent> <plug>(tug-maps-n) :<c-u>call tug#vim#maps('n', 0)<cr>
inoremap <silent> <plug>(tug-maps-i) <c-o>:call tug#vim#maps('i', 0)<cr>
xnoremap <silent> <plug>(tug-maps-x) :<c-u>call tug#vim#maps('x', 0)<cr>
onoremap <silent> <plug>(tug-maps-o) <c-c>:<c-u>call tug#vim#maps('o', 0)<cr>

let &cpo = s:cpo_save
unlet s:cpo_save
