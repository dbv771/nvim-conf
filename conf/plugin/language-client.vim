""" language-client.vim
""" configuration for the plugin autozimu/LanguageClient-neovim

let s:bash_cmd = [
  \ 'bash-language-server',
  \ 'start',
  \ ]


let s:cquery_cmd = ['cquery',
  \  '--init={'
  \  . '"cacheDirectory": "' . expand($HOME) . '/.cache/cquery"'
  \  . ','
  \  . '"completion": {'
  \  .   '"filterAndSort": false'
  \  . '}'
  \  .
  \  '}' ]
  " \  '--log-file=~/.local/share/cquery/cquery.log',

let s:clangd_cmd = ['clangd']

let s:js_ts_cmd = [
  \ 'javascript-typescript-stdio',
  \ ]
  " \  '--logfile', '~/.local/share/javascript_typescript_langserver/langserver.log',

let s:hie_cmd = [
  \  'hie-wrapper',
  \ ]
  " \ '--logfile', '~/.local/share/haskell-ide-engine/hie-wrapper_lcn.log',

let s:go_cmd = [
  \  'go-langserver',
  \  '-gocodecompletion',
  \ ]
  " \ '-usebinarypkgcache=0',
  " \ '-logfile', '~/.local/share/go-langserver/go-langserver.log',

let s:bingo_cmd = [
  \   'bingo',
  \   '-enable-global-cache',
  \ ]

let s:gopls_cmd = [
  \   'gopls',
  \   '-logfile', '~/.local/share/gopls.log',
  \   'server',
  \ ]

let s:ocaml_cmd = [
  \   'ocaml-language-server',
  \   '--stdio',
  \ ]


let s:vim_cmd = [
  \   'vim-language-server',
  \   '--stdio',
  \ ]

" LanguageClient-neovim
let g:LanguageClient_serverCommands = {
  \   'bash':           s:bash_cmd,
  \   'sh':             s:bash_cmd,
  \   'c':              s:cquery_cmd,
  \   'cpp':            s:cquery_cmd,
  \   'go':             s:gopls_cmd,
  \   'haskell':        s:hie_cmd,
  \   'ocaml':          s:ocaml_cmd,
  \   'reason':         s:ocaml_cmd,
  \   'javascript.jsx': s:js_ts_cmd,
  \   'javascript':     s:js_ts_cmd,
  \   'typescript':     s:js_ts_cmd,
  \   'vim':            s:vim_cmd,
  \ }
  " \    'go':             s:gopls_cmd,
  " \    'go':             s:go_cmd,

" Let ALE handle linting
let g:LanguageClient_diagnosticsEnable = 0
let g:LanguageClient_diagnosticsList = "Disabled"

" Fix for https://github.com/autozimu/LanguageClient-neovim/issues/379
let g:LanguageClient_hasSnippetSupport = 0

let g:LanguageClient_windowLogMessageLevel = "Error"

" LC Settings
let g:LanguageClient_autoStart = 1
let g:LanguageClient_hoverPreview = "Never"
let g:LanguageClient_completionPreferTextEdit = 0

let g:LanguageClient_trace = "off"  " 'off' | 'messages' | 'verbose'
let g:LanguageClient_loggingLevel = "ERROR" " 'DEBUG' | 'INFO' | 'WARN' | 'ERROR'
let g:LanguageClient_loggingFile = expand("~/.local/share/nvim/language-client.log")

"" 'LCHover' mini plugin

let g:LanguageClientHoverEnabled = 1
let g:LanguageClientHoverPreview = 1
let g:LanguageClientPreviewHeight = 1
let g:LanguageClientPreviewResize = "Focus" " 'Always' | 'Never' | 'Focus'
let g:LanguageClientPreviewResizeMax = 8
let g:LanguageClientHoverPreviewClose = 0
let g:LanguageClientPreviewBufName = "__LC_Hover_Info__"
let g:LanguageClientPreviewStatusline = "%<Hover"

let s:orig_preview_height = v:null

let s:serverStatus = v:false

func! LanguageClientStatusStart()
  let s:serverStatus = v:true
endfunc

func! LanguageClientStatusStop()
  let s:serverStatus = v:false
endfunc

func! LanguageClientStatus() " TODO
  if s:serverStatus == v:true
    return "LC"
  endif
  return ""
endfunc

augroup LanguageClientStatus
  autocmd!
  autocmd User LanguageClientStarted call LanguageClientStatusStart()
  autocmd User LanguageClientStopped call LanguageClientStatusStop()
augroup END

func! LanguageClientHoverToggle()
  let g:LanguageClientHoverEnabled = !g:LanguageClientHoverEnabled
  if g:LanguageClientHoverEnabled == 0
    call s:disableHover()
    echo "LanguageClientHover disabled"
  else
    call s:enableHover()
    echo "LanguageClientHover enabled"
  endif
endfunc

func! s:languageClientPreviewResize(action, size)
  if a:action == "Show"
    if g:LanguageClientPreviewResize != "Always"
      return
    endif
  elseif a:action == "Clear"
    if g:LanguageClientPreviewResize == "Never"
      return
    endif
  elseif a:action == "Focus"
    if index(["Always", "Focus"], g:LanguageClientPreviewResize) == -1
      return
    endif
  elseif a:action == "Unfocus"
    if g:LanguageClientPreviewResize != "Focus"
      return
    endif
  endif

  let l:previewBufnr = bufnr(g:LanguageClientPreviewBufName)
    let l:previewWinids = win_findbuf(l:previewBufnr)
    if len(l:previewWinids) > 0
      let l:maxHeight =  min([g:LanguageClientPreviewResizeMax, a:size])
      try
        call nvim_win_set_height(get(l:previewWinids, 0), l:maxHeight)
      catch /.*Vim:E315.*/
        " I don't know what causes this error... just smile and nod...
        return
      endtry
    endif
endfunc

func! s:languageClientPreviewInit()
  let l:cmds = [
    \   [ "let",
    \     "w:airline_disabled=1",
    \   ],
    \   [ "let",
    \     "b:ale_enabled=0",
    \   ],
    \   [ "setlocal",
    \     "statusline=" . g:LanguageClientPreviewStatusline,
    \     "filetype=" . &ft,
    \     "buftype=nofile",
    \     "noswapfile",
    \     "nonumber",
    \     "norelativenumber",
    \     "nomodeline",
    \   ],
    \ ]
  let l:cmdStr = join(map(l:cmds, { k, c -> join(c, "\\ ") }), "|")
  exec "silent! pedit! +" . l:cmdStr . " " . g:LanguageClientPreviewBufName
endfunc

let s:cleared = 0
let s:moved = 0
func! g:LanguageClientPreviewHoverCb(res)
  " If we get a valid response with non-empty result, display it
  if   type(a:res) == v:t_dict        && has_key(a:res, "result")
  \ && type(a:res.result) == v:t_dict && has_key(a:res.result, "contents")
    let l:msg = []
    if type(a:res.result.contents) == v:t_dict && type(a:res.result.contents.value) == v:t_string
      let l:msg += split(a:res.result.contents.value, "\n")
    elseif type(a:res.result.contents) == v:t_list
      for l:item in a:res.result.contents
        if type(l:item) == v:t_dict && type(l:item.value) == v:t_string
          let l:msg += split(l:item.value, "\n")
        endif
      endfor
    endif
    if len(l:msg) > 0
      if g:LanguageClientHoverPreview
        let l:previewBufnr = bufnr(g:LanguageClientPreviewBufName)
        if l:previewBufnr == -1 || len(win_findbuf(l:previewBufnr)) == 0
          call s:languageClientPreviewInit()
          let l:previewBufnr = bufnr(g:LanguageClientPreviewBufName)
        endif
        call s:languageClientPreviewResize("Show", len(l:msg))
        call nvim_buf_set_lines(l:previewBufnr, 0, len(l:msg), 0, l:msg)
      else
        echohl Keyword | echo join(l:msg, "\n") | echohl None
      endif
      let s:cleared = 0
      let s:moved = 0
      return
    endif
  endif
  " Clear output
  if s:cleared == 0
    if g:LanguageClientHoverPreview
      if g:LanguageClientHoverPreviewClose
        silent! pclose
      else
        let l:previewBufnr = bufnr(g:LanguageClientPreviewBufName)
        if l:previewBufnr != -1
          let l:lines = nvim_buf_get_lines(l:previewBufnr, 0, -1, 0)
          call s:languageClientPreviewResize("Clear", g:LanguageClientPreviewHeight)
          call nvim_buf_set_lines(l:previewBufnr, 0, len(l:lines), 0, [])
        endif
      endif
    else
      echo ""
    endif
    let s:cleared = 1
    let s:moved = 0
  endif
endfunc

function! s:languageClientPreviewHover() abort
    let l:params = {
      \ 'filename':  LSP#filename(),
      \ 'text':      LSP#text(),
      \ 'line':      LSP#line(),
      \ 'character': LSP#character(),
      \ 'handle':    v:false,
      \ }
    return LanguageClient#Call('textDocument/hover', l:params, function("LanguageClientPreviewHoverCb"))
endfunction

func! LanguageClientPreviewAliveCb(res)
  let s:serverStatus = a:res.result
  if s:serverStatus == v:true
    call s:languageClientPreviewHover()
  endif
endfunc

let s:lastline = ""
let s:lastpos = ""
func! s:hold()
  let l:line = getline(line("."))
  let l:pos = join(getpos("."), ",")
  if s:moved == 1 && g:LanguageClientHoverEnabled == 1
    \ && (l:line != s:lastline || l:pos != s:lastpos)
    let s:lastline = l:line
    let s:lastpos = l:pos
    call LanguageClient#isAlive(function("LanguageClientPreviewAliveCb"))
  endif
endfunc

let s:focus = 0

func! s:moved()
  let l:previewBufnr = bufnr(g:LanguageClientPreviewBufName)
  let l:previewWinids = win_findbuf(l:previewBufnr)
  let l:currWinid = win_getid()
  if index(l:previewWinids, l:currWinid) != -1 " Preview window is selected
    if s:focus == 0 " Trigger focus event
      let l:lines = nvim_buf_get_lines(l:previewBufnr, 0, -1, 0)
      call s:languageClientPreviewResize("Focus", len(l:lines))
      let s:focus = 1
    endif
    let s:moved = 0
    return
  endif
  if s:focus == 1 " Trigger unfocus event
    call s:languageClientPreviewResize("Unfocus", g:LanguageClientPreviewHeight)
    let s:focus = 0
  endif
  let s:moved = 1
endfunc

func! s:enableHover()
  if g:LanguageClientPreviewHeight >= 0
    let s:orig_preview_height = &previewheight
    exec "set previewheight=" . g:LanguageClientPreviewHeight
  endif
  augroup LanguageClient_textDocumentHover
    au!
    au CursorMoved * call <sid>moved()
    au CursorHold  * call <sid>hold()
  augroup END
endfunc

func! s:disableHover()
  if s:orig_preview_height
    exec "set previewheight=" . s:orig_preview_height
  endif
  augroup! LanguageClient_textDocumentHover
endfunc

augroup LanguageClientListener
  au!
  au User LanguageClientStarted call <sid>enableHover()
  au User LanguageClientStopped call <sid>disableHover()
augroup END
