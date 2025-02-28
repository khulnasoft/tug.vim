function! tug#vim#listproc#quickfix(list)
  call setqflist(a:list)
  copen
  wincmd p
  cfirst
  normal! zvzz
endfunction

function! tug#vim#listproc#location(list)
  call setloclist(0, a:list)
  lopen
  wincmd p
  lfirst
  normal! zvzz
endfunction
