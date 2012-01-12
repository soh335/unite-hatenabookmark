if !exists('g:unite_hatenabookmark_print_pattern')
  let g:unite_hatenabookmark_print_pattern = "[title]"
endif

let s:source = {
      \ 'name': 'hatenabookmark',
      \ 'action_table': {},
      \ 'default_action': { 'uri' : 'open' },
      \ 'max_candidates': 30,
      \}

function! unite#sources#hatenabookmark#define()
  if exists('g:unite_hatenabookmark_username')
    return s:source
  endif
  return {}
endfunction

function! s:parse_pattern()
  let res = { 'pattern' : g:unite_hatenabookmark_print_pattern, 'indexes' : [] }

  let list = []
  for type in ["comment", "title", "url"]
    let index = match(res.pattern, printf('\[%s\]', type))
    if index > -1
      let res.pattern = substitute(res.pattern, printf('\[%s\]', type), '%s', "")
      call add(list, { 'key' : type, 'value' : index })
    endif
  endfor

  let res.indexes = map(sort(list, 's:dict_sort'), 'v:val.key')

  return res
endfunction

function! s:dict_sort(a, b)
  return a:a.value - a:b.value
endfunction

function! s:parse_args(res, obj)
  let list = [a:res.pattern]
  for index in a:res.indexes
    call add(list, a:obj[index])
  endfor
  return list
endfunction

function! s:source.gather_candidates(args, context)
  let bookmarks = []
  let res = http#get(printf("http://b.hatena.ne.jp/%s/search.data", 
        \ g:unite_hatenabookmark_username))

  let i = 0
  let obj = {}
  let parse_res = s:parse_pattern()

  for line in split(res.content, "\n")
    if line =~ '^\d\+\t\d\+$'
      break
    endif

    if i == 0
      let obj.title = line
    elseif i == 1
      let obj.comment = line
    elseif i == 2
      let obj.url = line
      call add (bookmarks, {
            \ 'word': call("printf", s:parse_args(parse_res, obj)),
            \ 'kind': 'uri',
            \ 'source': 'hatenabookmark',
            \ 'action__path': obj.url
            \})
      let i = 0
      let obj = {}
      continue
    endif

    let i = i + 1
  endfor
  return bookmarks
endfunction

" action
let s:action_table = {}

let s:action_table.open = {
      \   'description': 'open selected bookmark in browser'
      \}

let s:source.action_table.uri = s:action_table

function! s:action_table.open.func(candidate)
  call openbrowser#open(a:candidate.action__path)
endfunction
