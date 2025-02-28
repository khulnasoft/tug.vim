function! s:warn(message)
  echohl WarningMsg
  echom a:message
  echohl None
  return 0
endfunction

function! tug#vim#ipc#start(Callback)
  if !exists('*job_start') && !exists('*jobstart')
    call s:warn('job_start/jobstart function not supported')
    return ''
  endif

  if !executable('mkfifo')
    call s:warn('mkfifo is not available')
    return ''
  endif

  call tug#vim#ipc#stop()

  let g:tug_ipc = { 'fifo': tempname(), 'callback': a:Callback }
  if !filereadable(g:tug_ipc.fifo)
    call system('mkfifo '..shellescape(g:tug_ipc.fifo))
    if v:shell_error
      call s:warn('Failed to create fifo')
    endif
  endif

  call tug#vim#ipc#restart()

  return g:tug_ipc.fifo
endfunction

function! tug#vim#ipc#restart()
  if !exists('g:tug_ipc')
    throw 'tug#vim#ipc not started'
  endif

  let Callback = g:tug_ipc.callback
  if exists('*job_start')
    let g:tug_ipc.job = job_start(
          \ ['cat', g:tug_ipc.fifo],
          \ {'out_cb': { _, msg -> call(Callback, [msg]) },
          \  'exit_cb': { _, status -> status == 0 ? tug#vim#ipc#restart() : '' }}
          \ )
  else
    let eof = ['']
    let g:tug_ipc.job = jobstart(
          \ ['cat', g:tug_ipc.fifo],
          \ {'stdout_buffered': 1,
          \  'on_stdout': { j, msg, e -> msg != eof ? call(Callback, msg) : '' },
          \  'on_exit': { j, status, e -> status == 0 ? tug#vim#ipc#restart() : '' }}
          \ )
  endif
endfunction

function! tug#vim#ipc#stop()
  if !exists('g:tug_ipc')
    return
  endif

  let job = g:tug_ipc.job
  if exists('*job_stop')
    call job_stop(job)
  else
    call jobstop(job)
    call jobwait([job])
  endif

  call delete(g:tug_ipc.fifo)
  unlet g:tug_ipc
endfunction
